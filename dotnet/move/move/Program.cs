using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text.RegularExpressions;
using Mono.Options;
using CSITools;


/*
SPEC:

    This program moves files in the azure git repo.
    1. Dependencies:
        a) .NET Full build, not core. 
        b) lib2gitsharp, which requires native binaries to be installed.
        c) works off the current repo you are in. Neither changes branches nor pulls or pushes. 
        d) does create commits locally, as it is necessary to commit changes in order to work on those files at moments. git is tricky.
    2. Algorithm
        a) takes a file list as an argument in regular path format.
        b) takes a directory to place them in

 */

namespace links
{
    class MainClass
    {

        private static bool redirects = false;
        private static bool commit = false;

        public static void Main(string[] args)
        {
            string sourcePattern = "";
            string targetPattern = "";
            string workingRepoDir = Directory.GetCurrentDirectory() + @"\";
            bool show_help = false;

            var p = new OptionSet()
            { 
                /*{
                    "d|directory",
                    "Specifies the root directory of the repo to use; default is current directory.",
                    (string v) => workingRepoDir = v
                },
                */
                {
                    "h|help",
                    "Displays this help for \"move\"",
                    v => show_help = v != null
                },
                { "r|redirect", "Indicates that moved file should be replaced with a redirect file to the new target; default is true.", v => redirects = true  },
                { "c|commit", "Indicates that all changes should be committed; default is to leave all changes **staged** (\"added\", in git terminology, but not committed) so that \"git diff --cached\" will immediately display the changes.", v => commit = true }
            };

            List<string> argList;

            try {
                argList = p.Parse (args);
            }
            catch (OptionException e) {
                Console.Write ("move: ");
                Console.WriteLine (e.Message);
                Console.WriteLine ("Try 'move --help' for more information.");
                return;
            }

            if (show_help) {
                ShowHelp (p);
                return;
            }

            GitMover mover = null;  
            try
            {
                mover = new GitMover(workingRepoDir, argList[0], argList[1], redirects, commit);
                mover.Move();
                mover.Dispose();
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Error: {0}: ", ex.Message);
                Console.ResetColor();
                ShowHelp(p);
                if (mover != null)
                {
                    mover.Unwind();
                    mover.Dispose();
                }
            }
            Console.WriteLine("done");
            Console.ReadLine();


        }

        static void ShowHelp (OptionSet p)
        {
            Console.WriteLine ("Usage: move <source filespec> <target filespec>");
            Console.WriteLine();
            Console.WriteLine ("Move a single markdown file to the specified path, including media files, and rewrite all inbound links.");
            Console.WriteLine ();
            Console.WriteLine ("Options:");
            p.WriteOptionDescriptions (Console.Out);
        }

    }

}


