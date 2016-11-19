using LibGit2Sharp;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace rewritelink
{
    internal class Replacements
    {
        Repository repo;
        const string repodir = @"C:\Users\rasquill\documents\github\azure-docs-pr\";

        public Replacements()
        {
           
        }

        internal void Run()
        {

            using (repo = new Repository(repodir))
            {
                //repo.Checkout("master");
                //repo.Fetch("docs", new FetchOptions {  })
                Console.WriteLine("repo branch is: " + repo.Head.FriendlyName);
                IEnumerable<IndexEntry> targets = from f in repo.Index
                                       where f.Path.Contains(".md")
                                       && f.Path.Contains(@"virtual-machines\virtual-machines-linux-classic")
                                       //&& !f.Path.Contains("classic-")
                                       select f;

                IEnumerable<IndexEntry> allFiles = from f in repo.Index
                                       where f.Path.Contains(".md")
                                       select f;

                foreach (var linkFile in targets)
                {
                    RewriteInboundLinks(repodir + linkFile.Path, allFiles);
                }
                Console.WriteLine("done.");
                Console.ReadLine();
            }
        }

        internal void RewriteInboundLinks(string fileToContextualize, IEnumerable<IndexEntry> allFiles)
        {
            string fileLinkShortName = fileToContextualize.Substring(fileToContextualize.LastIndexOf(@"\") + 1);

            Regex contextPattern = new Regex(@"virtual-machines-linux-classic-.+?\.md(?=\?toc=)");
            Regex noContextPattern = new Regex(fileLinkShortName + @"\)");
            foreach (IndexEntry fileToExamine in allFiles)
            {
                string fileTextToExamine = File.ReadAllText(this.repo.Info.WorkingDirectory + Path.DirectorySeparatorChar + fileToExamine.Path);
                if (fileTextToExamine == string.Empty)
                {
                    throw new Exception(this.repo.Info.WorkingDirectory + Path.DirectorySeparatorChar + fileToExamine.Path);
                }

                if (Regex.IsMatch(fileTextToExamine, noContextPattern.ToString()))
                {
                    var results = Regex.Replace(fileTextToExamine, noContextPattern.ToString(), fileLinkShortName + @"?toc=%2fazure%2fvirtual-machines%2flinux%2fclassic%2ftoc.json)");
                    File.WriteAllText(this.repo.Info.WorkingDirectory + fileToExamine.Path, results);
                    Console.WriteLine("match rewritten");
                }
                else
                    Console.WriteLine("no match");
            }

        }

        internal static bool ContainsInboundLinks(string path)
        {
            bool containsLinkHit = false;
            Regex contextPattern = new Regex(@"virtual-machines-linux-.+?\.md(?=\?toc=)");
            Regex noContextPattern = new Regex(@"virtual-machines-linux-.+?\.md(?=\))");
            //Regex noContextPattern = new Regex(@"virtual-machines-linux-");
            if (noContextPattern.IsMatch(File.ReadAllText(path)))
            {
                containsLinkHit = true;
                //Console.WriteLine(path.Substring(path.LastIndexOf(@"\") + 1) + " : " + noContextPattern.Matches(File.ReadAllText(path)).ToString());
            }

            return containsLinkHit;
        }
    }
}