using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace tocimport
{
    class Program
    {
        static void Main(string[] args)
        {
            string resourceFile = string.Format(@"C:\Users\rasquill\Documents\GitHub\acom\code\acom\ACOM.Resources\Shared\Lefties\{0}.resx", args[0]);
            string tocJason= string.Format(@"C:\Users\rasquill\Documents\GitHub\acom\code\acom\Acom.Json\Data\Lefties\{0}.contentmap.json", args[0]);

            // get the json 
            JObject json = JObject.Parse(File.ReadAllText(tocJason));
            JObject H1s = json.Root as JObject;

            // get the resx
            XDocument resx = XDocument.Load(resourceFile);

            foreach (JProperty jsonValue in H1s.Properties())
            {
                Console.WriteLine("# "+GetMappedName(jsonValue, json, resx));
                foreach (JProperty H2 in H1s[jsonValue.Name])
                {
                    Console.WriteLine("## ["+ GetMappedName(H2, json, resx).Trim() + "](" + ConvertLink(H2.Value) + ")");
                    //Console.ReadKey();
                }
            }

            //Console.ReadKey();
        }


        /*
         * 
         *                    article_string=${article_string//acom:/https://azure.microsoft.com}
                    article_string=${article_string//msdn:/https://msdn.microsoft.com/en-us/library/azure/}
                                        article_string=${article_string//link:/} 
        */
        private static string ConvertLink(JToken value)
        {
            string cleaned = value.ToString();
            cleaned=cleaned.Replace("acom:", "https://azure.microsoft.com");
            cleaned=cleaned.Replace("msdn:", "https://msdn.microsoft.com/en-us/library/azure/");
            cleaned=cleaned.Replace("link:", "");
            cleaned = cleaned.Replace("article:", "");
            if (!cleaned.Contains("http"))
            {
                cleaned = cleaned + ".md";
            }

            return cleaned;
        }

        private static string GetMappedName(JProperty jsonValue, JObject json, XDocument resx)
        {
            //string returnValue = string.Empty;
            var datas = from data in resx.Descendants("data") select data;
            foreach (XElement name in datas)
            {
                foreach (XElement value in name.Descendants("value"))
                {
                    if (jsonValue.Name.Equals(name.Attribute("name").Value))
                    {
                        return value.Value;
                    }
                }
            }
            return string.Empty;
        }

    }
}
