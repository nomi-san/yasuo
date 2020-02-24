using System;
using System.Linq;
using System.Threading;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Authentication;
using System.Windows.Forms;
using System.IO;
using System.Text.RegularExpressions;
using WebSocketSharp;
using System.Collections.Generic;

class LastBreath
{
    private static string PORT, PASS;
    private static HttpClient CLIENT;
    private static WebSocket CONN;
    private static bool connected;
    private const string listener = "OnJsonApiEvent";

    private static Regex CHAT_REGEX = new Regex("conversations/(.+?)/messages/\\w");
    private static Regex CHSLCT_REGEX = new Regex("\"eventType\":\"Create\",\"uri\":\"/lol-champ-select/v1/session\"");
    private static Regex MCHFND_REGEX = new Regex("/lol-matchmaking/v1/ready-check");
    private static Regex SLCTED_REGEX = new Regex("/lol-champ-select/v1/sfx-notifications");

    private static Regex PASS_REGEX = new Regex("\"--remoting-auth-token=(.+?)\"");
    private static Regex PORT_REGEX = new Regex("\"--app-port=(\\d+?)\"");

    private static Regex CMD_REGEX = new Regex("^\\/[?A-zA-Z]+");

    private static string prevChatId = "";
    private static int actionId = -1;

    public static bool IsConnected => connected;

    public static void Intend()
    {
        Process lcu = null;
        while (lcu == null)
        {
            var list = Process.GetProcessesByName("LeagueClientUx");
            if (list.Length > 0) lcu = list[0];
            Thread.Sleep(500);
        };

        lcu.EnableRaisingEvents = true;
        lcu.Exited += ((sender, e) => OnLCUClosed());
        OnLCUOpened(Path.GetDirectoryName(lcu.MainModule.FileName));
    }

    public static void Resolve()
    {
        try
        {
            CLIENT = new HttpClient(new HttpClientHandler()
            {
                SslProtocols = SslProtocols.Tls12 | SslProtocols.Tls11 | SslProtocols.Tls,
                ServerCertificateCustomValidationCallback = (a, b, c, d) => true
            });
        }
        catch
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 |
                SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;
            CLIENT = new HttpClient(new HttpClientHandler()
            {
                ServerCertificateCustomValidationCallback = (a, b, c, d) => true
            });
        }

        try
        {
            var bytes = System.Text.Encoding.ASCII.GetBytes("riot:" + PASS);
            CLIENT.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
                "Basic", Convert.ToBase64String(bytes));

            CONN = new WebSocket("wss://127.0.0.1:" + PORT + "/", "wamp");
            CONN.SetCredentials("riot", PASS, true);

            CONN.SslConfiguration.EnabledSslProtocols = SslProtocols.Tls12;
            CONN.SslConfiguration.ServerCertificateValidationCallback = (a, b, c, d) => true;
            CONN.OnMessage += OnMessage;
            CONN.OnClose += OnClose;
            CONN.Connect();
            CONN.Send("[5,\"" + listener + "\"]");

            connected = true;
        }
        catch
        {
            connected = false;
        }

        if (connected) OnInitialized();
    }

    private static string Request(string method, string uri, string body = null)
    {
        if (!connected) return null;

        try
        {
            var content = (body != null) ?
                new StringContent(body, System.Text.Encoding.UTF8, "application/json") : null;

            var response = CLIENT.SendAsync(new HttpRequestMessage(
                new HttpMethod(method), "https://127.0.0.1:" + PORT + uri) {
                Content = content
            }).Result;

            if (response.IsSuccessStatusCode)
            {
                var responseContent = response.Content;
                return responseContent.ReadAsStringAsync().Result;
            }
        }
        catch { }

        return null;
    }

    public static void Echo(string msg = "")
    {
        if (!connected || prevChatId.IsNullOrEmpty()) return;

        var body = "{\"body\":\"" + (msg) + "\"}";
        Request("POST", $"/lol-chat/v1/conversations/{prevChatId}/messages", body);
    }

    public static void Quit()
    {
        if (connected)
        {
            connected = false;
            CONN.Close();
        }
       
        Application.Exit();
    }

    private static void OnMessage(object sender, MessageEventArgs meArgs)
    {
        if (!connected) return;
        if (!meArgs.IsText) return;
        var data = meArgs.Data;

        if (Int32.Parse(data.Substring(1, 1)) != 8) return;
        if (!data.Substring(4, listener.Length).Equals(listener)) return;

        var json = data.Substring((4+2) + listener.Length,
            data.Length - listener.Length - (4+2+1));

        Match match;
        if ((match = CHAT_REGEX.Match(json)).Success)
        {
            prevChatId = match.Groups[1].Value;
            var body = Unforgiven.Parse<Unforgiven.Root<Unforgiven.Message>>(json).data.body;

            if (CMD_REGEX.IsMatch(body))
            {
                var tokens = body.ToLower().Split(' ');
                var cmd = tokens[0].Remove(0, 1);
                var args = tokens.Skip(1).ToArray();

                WashingPole.OnCommand(cmd, args);
            }
        }
        else if (CHSLCT_REGEX.IsMatch(json))
        {
            var session = Unforgiven.Parse<Unforgiven.Root<Unforgiven.ChampSelectSession>>(json).data;
            var myCellId = session.localPlayerCellId;

            session.actions[0].Where((v) => {
                if (myCellId == v.actorCellId) actionId = v.id;
                return true;
            }).ToArray();   // Without calling ToArray, this code is not executed.

            WashingPole.OnChampSelect(actionId);
        }
        else if (MCHFND_REGEX.IsMatch(json))
        {
            WashingPole.OnMatchFound();
        }
        else if (SLCTED_REGEX.IsMatch(json))
        {
            // We had actionId when Champ Select is created.
            WashingPole.OnAfterPicked(actionId);
        }
    }

    private static void OnClose(object sender, CloseEventArgs args)
    {
        Quit();
    }

    private static void OnLCUOpened(string path)
    {
        Process wmic = new Process();
        wmic.StartInfo = new ProcessStartInfo("cmd") {
            UseShellExecute = false,
            RedirectStandardOutput = true,
            CreateNoWindow = true,
            Arguments = "/c WMIC PROCESS WHERE name='LeagueClientUx.exe' GET commandline"
        };
        wmic.Start();
        string output = wmic.StandardOutput.ReadToEnd().Trim();
        wmic.WaitForExit();

        PASS = PASS_REGEX.Match(output).Groups[1].Value;
        PORT = PORT_REGEX.Match(output).Groups[1].Value;
        Thread.Sleep(2500);
    }

    private static void OnLCUClosed()
    {
        Quit();
    }

    private static void OnInitialized()
    {
        // First request :D
        var json = Request("GET", "/riotclient/get_region_locale");
        
        if (json != null)
        {
            var region = Unforgiven.Parse<Unforgiven.Region>(json);
            WashingPole.SetLanguage(region.webLanguage);
        }
        else
        {
            connected = false;
        }
    }

    public static bool PickChamp(int actId, int champId)
    {
        var json = Request("PATCH",
            $"/lol-champ-select/v1/session/actions/{actId}",
            "{\"championId\":" + champId + "}");
        return json.Equals("");
    }

    public static bool LockChamp(int actId)
    {
        var json = Request("POST",
            $"/lol-champ-select/v1/session/actions/{actId}/complete");
        return json.Equals("");
    }

    public static void AcceptMatch()
    {
        Request("POST", "/lol-matchmaking/v1/ready-check/accept");
    }

    public static IList<Unforgiven.Champion> GetPlayableChamps()
    {
        var json = Request("GET",
            "/lol-champions/v1/owned-champions-minimal");
        return Unforgiven.Parse<IList<Unforgiven.Champion>>(json);
    }
}
