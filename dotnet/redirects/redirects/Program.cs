using LibGit2Sharp;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace redirects
{
    class Program
    {
        static void Main(string[] args)
        {
            const string redirectSource = @"C:\Users\rasquill\Documents\GitHub\acom\code\acom\ACOM.Web\config\rewriteMaps.config";
            const string localRepo = @"C:\Users\rasquill\Documents\GitHub\azure-docs-pr";
            XDocument redirectXDoc = XDocument.Load(redirectSource);
            var redirectGroups = from r in redirectXDoc.Root.Descendants("add") where !r.Attribute("value").Value.Contains("http") select r;
            var groups =
                from g in redirectGroups
                select new RedirectEntry
                {
                    parentname = g.Parent.Value,
                    oldTarget = g.Attribute("key").Value,
                    newTarget = g.Attribute("value").Value
                };
            var keyhits = from hit in groups where hit.oldTarget.StartsWith("/documentation/articles") select hit;
            /*
            Console.WriteLine("Original URL, Redirect URL");

            foreach (var hit in keyhits)
            {
                Console.WriteLine(hit.oldTarget + "," + hit.newTarget);
            }
            */

            using (Repository repo = new Repository(localRepo /*, new RepositoryOptions() { WorkingDirectoryPath = this.originalRepo} */))
            {
                //Console.WriteLine(repo.Info.WorkingDirectory);
                repo.Checkout("master");
                //Console.WriteLine(repo.Index.Count());

                var files = (from f in repo.Index
                         where 
                            f.Path.Contains(".md") 
                            && !f.Path.Contains("TOC.md")
                            && !f.Path.Contains("index.md")
                            && f.Path.Contains(@"articles\")
                         select f.Path);

                //Console.WriteLine("XML Redirect line");
                foreach (string file in files)
                {

                    /*
<add key="/documentation/articles/mobile-services-android-add-paging-data/" 
value="/documentation/articles/mobile-services-android-how-to-use-client-library/#paging" />                     * */

                    StringBuilder builder = new StringBuilder();
                    //builder.Append("<add key=\"");
                    builder.Append(AcomLinkifyPath(file));
                    builder.Append(",");
                    //builder.Append("\" value=\"");
                    builder.Append(DocLINKifyPath(file));
                    //builder.Append("\" />");
                    Console.WriteLine(builder.ToString());
                }
            }
        }

        private static string AcomLinkifyPath(string file)
        {
            string tempFragment = "/documentation/articles/";
            // add the url
            tempFragment += file.Substring(file.LastIndexOf('\\') + 1);
            tempFragment = tempFragment.Replace(".md", @"/");
            return tempFragment;
        }

        private static string DocLINKifyPath(string file)
        {
            string tempFragment = "https://docs.microsoft.com/azure/";
            // add the url
            tempFragment += file.Replace(@"articles\", string.Empty);
            tempFragment = tempFragment.Replace(".md", "");
            tempFragment = tempFragment.Replace(@"\", @"/");
            tempFragment = Contextify(tempFragment);
            return tempFragment;
        }

        private static string Contextify(string tempFragment)
        {
            string newDocLinkString = tempFragment;
            if (tempFragment.Contains("virtual-machines-windows-classic"))
            {
                return tempFragment + "?toc=%2fazure%2fvirtual-machines%2fwindows%2fclassic%2ftoc.json";
            }
            if (tempFragment.Contains("virtual-machines-windows"))
            {
                return tempFragment + "?toc=%2fazure%2fvirtual-machines%2fwindows%2ftoc.json";
            }
            if (tempFragment.Contains("virtual-machines-linux-classic"))
            {
                return tempFragment + "?toc=%2fazure%2fvirtual-machines%2flinux%2fclassic%2ftoc.json";
            }
            if (tempFragment.Contains("virtual-machines-linux"))
            {
                return tempFragment + "?toc=%2fazure%2fvirtual-machines%2flinux%2ftoc.json";
            }
            return tempFragment;
        }
    }

    internal class RedirectEntry
    {
        public string newTarget { get; set; }
        public string oldTarget { get; set; }
        public string parentname { get; set; }
    }
}
