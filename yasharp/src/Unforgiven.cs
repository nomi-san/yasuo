using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.Script.Serialization;

class Unforgiven
{
    public static T Parse<T>(string json)
    {
        try
        {
            if (json == null || json == "") return default(T);
            return new JavaScriptSerializer().Deserialize<T>(json);
        }
        catch
        {
            return default(T);
        }
    }

    public class Root<T>
    {
        public T data { get; set; }
        public string eventType { get; set; }
        public string uri { get; set; }
    }

    public class Message
    {
        public string body { get; set; }
        public string id { get; set; }
    }

    public class Region
    {
        public string webLanguage { get; set; }
    }

    public class ChampSelectSession
    {
        public class Action
        {
            public int actorCellId { get; set; }
            public int id { get; set; }
        }

        public IList<IList<Action> > actions { get; set; }
        public int localPlayerCellId { get; set; }
    }

    public class Champion
    {
        public string alias { get; set; }
        public int id { get; set; }
        public string name { get; set; }
    }
}
