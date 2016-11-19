using LibGit2Sharp;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CarolsSpecialReport
{
    class Program
    {
        static void Main(string[] args)
        {
            string repopath = @"C:\users\rasquill\documents\github\azure-docs-pr\";
            List<TOC> TOCs = new List<TOC>();

            using (Repository repo = new Repository(repopath))
            {
                repo.Checkout("master");
                //Console.WriteLine(repo.Index.Count());

                var tocfiles = (from f in repo.Index
                             where
                                f.Path.Contains("TOC.md")
                                && f.Path.Contains(@"articles\")
                             select f.Path);
                foreach (var tocfile in tocfiles)
                {
                    //Console.WriteLine(File.ReadAllText(repo.Info.WorkingDirectory + tocfile));
                    TOCs.Add(new TOC(repo.Info.WorkingDirectory + tocfile));
                }
            }

            Console.ReadLine();
        }
    }
}
