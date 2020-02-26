using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

class WashingPole
{
    private static string
        msgLangChanged,
        msgHelp,
        msgUnknow,
        msgExited;

    private static string
        msgAutoAcceptIsOn,
        msgAutoAcceptIsOff;

    private static string
        msgAutoLockIsOn,
        msgAutoLockIsOff;

    private static string
        msgChampOK,
        msgChampNotFound;

    private static Dictionary<string, string> dictHelper = new Dictionary<string, string>();

    private static bool autoLock = false;
    private static bool autoAccept = false;
    private static List<Unforgiven.Champion> champIds = new List<Unforgiven.Champion>();

    public static void OnCommand(string cmd, string[] args)
    {
        if (cmd.Equals("lang"))
        {
            if (args.Length > 0)
            {
                SetLanguage(args[0]);
                Send(msgLangChanged);
            }
        }
        else if (cmd.Equals("help"))
        {
            Send(msgHelp);
        }
        else if (cmd.Equals("?"))
        {
            if (args.Length == 0)
            {
                Send(msgHelp);
            }
            else
            {
                cmd = args[0].Replace("/", "");
                ShowHelp(cmd);
            }
        }
        else if (cmd.Equals("exit") || cmd.Equals("q"))
        {
            Send(msgExited);
            LastBreath.Quit();
        }
        else if (cmd.Equals("auto"))
        {
            if (args.Length == 0)
                autoAccept = !autoAccept;
            else if (args[0].Equals("on"))
                autoAccept = true;
            else if (args[0].Equals("off"))
                autoAccept = false;

            Send(autoAccept ? msgAutoAcceptIsOn : msgAutoAcceptIsOff);
        }
        else if (cmd.Equals("lock"))
        {
            if (args.Length == 0)
                autoLock = !autoLock;
            else if (args[0].Equals("on"))
                autoLock = true;
            else if (args[0].Equals("off"))
                autoLock = false;

            Send(autoLock ? msgAutoLockIsOn : msgAutoLockIsOff);
        }
        else if (cmd.Equals("pick"))
        {
            champIds.Clear();
            
            if (args.Length > 0)
            {
                var champs = LastBreath.GetPlayableChamps();
                foreach (var _n in args)
                {
                    var name = DecodeName(_n);
                    var champ = GetChampFromList(champs, name);
                    if (champ != null)
                    {
                        champIds.Add(champ);
                        Send(msgChampOK + champ.name + ".");
                    }
                    else
                    {
                        Send(msgChampNotFound + $"'{_n}'.");
                    }
                }
            }
        }
        else if (cmd.Equals("status") || cmd.Equals("stt"))
        {
            string stt = (autoAccept ? msgAutoAcceptIsOn : msgAutoAcceptIsOff);
            stt += "\\n" + (autoLock ? msgAutoLockIsOn : msgAutoLockIsOff);

            foreach (var champ in champIds)
            {
                stt += "\\n" + (msgChampOK + champ.name + ".");
            }           

            Send(stt);
        }
        else
        {
            Send(msgUnknow);
        }
    }

    public static void OnMatchFound()
    {
        if (autoAccept)
        {
            LastBreath.AcceptMatch();
        }
    }

    public static void OnChampSelect(int actId)
    {
        if (champIds.Count > 0)
        {
            foreach (var champ in champIds)
            {
                if (LastBreath.PickChamp(actId, champ.id))
                {
                    break;
                }
            }
            if (autoLock)
            {
                LastBreath.LockChamp(actId);
            }
        }
    }

    public static void OnAfterPicked(int actId)
    {
        if (autoLock && champIds.Count == 0)
        {
            LastBreath.LockChamp(actId);
        }
    }

    private static void Send(string msg = "")
    {
        LastBreath.Echo($"[Bot] {msg}");
    }

    public static void SetLanguage(string id = "en")
    {
        if (id.Equals("vn") || id.Equals("vi"))
        {
            msgHelp = string.Join("\\n", new string[] {
                "Danh sách lệnh:",
                    "/help /?",
                    "/? [lệnh]",
                    "/exit /q",
                    "/status /stt",
                    "/lang [id]",
                    "/auto [on/off]",
                    "/pick [tên1] [tên2]...",
                    "/lock [on/off]"
            });

            msgLangChanged = "Ngôn ngữ đã thay đổi.";
            msgExited = "Hệ thống đã thoát.";
            msgUnknow = "Lệnh không hỗ trợ, gõ /help hoặc /? để xem các lệnh.";

            msgAutoAcceptIsOn = "Đã bật auto chấp nhận trận đấu.";
            msgAutoAcceptIsOff = "Đã tắt auto chấp nhận trận đấu.";

            msgAutoLockIsOn = "Đã bật auto lock tướng.";
            msgAutoLockIsOff = "Đã tắt auto lock tướng.";

            msgChampOK = "Đã chọn: ";
            msgChampNotFound = "Không tìm thấy hoặc bạn không sở hữu tướng có tên: ";

            dictHelper["help"] = "Lệnh /help\\n- Xem danh sách các lệnh.";
            dictHelper["?"] = "Lệnh /?\\n- Xem danh sách các lệnh.\\n- [lệnh] Xem cách dùng lệnh.";
            dictHelper["exit"] = 
                dictHelper["q"] = "Lệnh /exit hoặc /q để thoát.";
            dictHelper["status"] =
                dictHelper["stt"] = "Lệnh /status hoặc /stt để hiện trạng thái cài đặt.";
            dictHelper["lang"] = "Lệnh /lang\\n- Thay đổi ngôn ngữ, hiện tại chỉ hỗ trợ English (en), Tiếng Việt (vi).\\n" +
                "- Ví dụ: `/lang en` để thay đổi sang tiếng Anh";
            dictHelper["auto"] = "Lệnh /auto\\n- Bật/tắt auto chấp nhận trận dấu.\\n- Ví dụ: `/auto on`";
            dictHelper["lock"] = "Lệnh /lock\\n- Bật/tắt auto khóa tướng sau khi chọn.\\n- Ví dụ: `/pick on`";
            dictHelper["pick"] = "Lệnh /pick\\n- Tự động pick tướng khi bắt đầu Chọn Tướng.\\n" +
                "- Ví dụ: `/pick ys zed yi`\\n" +
                "+ Hệ thống sẽ tự động pick Yasuo.\\n" +
                "+ Nếu Yasuo đã có người chọn, thì đến Zed và Master Yi.\\n" +
                "- Ví dụ: `/pick` (không tham số) để tắt auto.";
        }
        else if (id.Equals("en"))
        {
            msgHelp = string.Join("\\n", new string[] {
                "Command list:",
                    "/help /?",
                    "/? [command]",
                    "/exit /q",
                    "/lang [id]",
                    "/pick [name]...",
                    "/auto [on/off]"
            });

            msgLangChanged = "Language has been changed.";
            msgExited = "System has been exited.";
            msgUnknow = "The command is not supported, please type /help or /? to show command list.";

            msgAutoAcceptIsOn = "Auto accept is on.";
            msgAutoAcceptIsOff = "Auto accept is off.";

            msgAutoLockIsOn = "Auto lock is on.";
            msgAutoLockIsOff = "Auto lock is off.";

            msgChampOK = "Selected: ";
            msgChampNotFound = "Couldn't find or you don't own the champion named: ";

            dictHelper["help"] = "Command /help\\n- Show command list.";
            dictHelper["?"] = "Command /?\\n- Show command list.\\n- [command] Show command usage.";
            dictHelper["exit"] =
                dictHelper["q"] = "Command /exit or /q to exit.";
            dictHelper["status"] =
                dictHelper["stt"] = "Command /status or /stt to show setting status.";
            dictHelper["lang"] = "Command /lang\\n- Change language, currently support only English (en), tiếng Việt (vi).\\n" +
                "- Ex: `/lang vi` to change language to Vietnamese";
            dictHelper["auto"] = "Command /auto\\n- Turn on/off auto accept when match found.\\n- Ex: `/auto on`";
            dictHelper["lock"] = "Command /lock\\n- Turn on/off auto lock after picked.\\n- Ex: `/pick off`";
            dictHelper["pick"] = "Command /pick\\n- Auto pick on Champ Select starts.\\n" +
                "- Ex: `/pick ys zed yi`\\n" +
                "+ The system will pick Yasuo.\\n" +
                "+ If Yasuo is picked by another, then the next is Zed.. and Master Yi .\\n" +
                "- Ex: `/pick` (no parameter) to turn off auto.";
        }
    }

    private static void ShowHelp(string cmd)
    {
        string msg;

        if (dictHelper.TryGetValue(cmd, out msg))
        {
            Send(msg);
        }
        else
        {
            Send(msgUnknow);
        }
    }

    private static string DecodeName(string name)
    {
        switch (name)
        {
            case "aa":
                return "aatrox";
            case "fish":
                return "fizz";
            case "iv": case "j4": case "jav":
                return "jarvaniv";
            case "kama": // Karma.js :D
                return "karma";
            case "kenen":
                return "kennen";
            case "ilao":
                return "illaoi";
            case "lee":
                return "leesin";
            case "lx":
                return "lux";
            case "md":
                return "drmundo";
            case "moon":
                return "diana";
            case "moder":
                return "mordekaiser";
            case "neko":
                return "neeko";
            case "pig":
                return "sejuani";
            case "popi": case "popy":
                return "poppy";
            case "sun":
                return "leona";
            case "susan":
            case "dog":
                return "nasus";
            case "tam":
                return "tahmkench";
            case "tf":
                return "twistedfate";
            case "tw":
                return "twitch";
            case "vaybu":
                return "vayne";
            case "wk": case "wukong":
                return "monkeyking";
            case "xz":
                return "xinzhao";
            case "yi":
                return "masteryi";
            case "ys":
                return "yasuo";
            case "yum": case "cat": case "meo": case "meow":
                return "yuumi";
        }
        return name;
    }

    private static Unforgiven.Champion GetChampFromList(IList<Unforgiven.Champion> champs, string name)
    {
        foreach (var champ in champs)
        {
            if (champ.alias.ToLower().Contains(name))
            {
                return champ;
            }
        }

        return null;
    }
}
