using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Text.RegularExpressions;
using CommandLine;
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

        public static void Main(string[] args)
        {
            string repoDir = "";

            Options options = new Options();
            try
            {
                if (CommandLine.Parser.Default.ParseArguments(args, options))
                {
                    if (options.ShowHelp)
                    {
                        Console.WriteLine(CommandLine.Text.HelpText.AutoBuild(options));
                    }

                    if (String.IsNullOrEmpty(options.RepoDir))
                    {
                        // Use the current directory if the user didn't specify --repo-dir
                        repoDir = Directory.GetCurrentDirectory() + @"\";
                    }
                    else
                    {
                        repoDir = options.RepoDir + @"\";
                    }
                }
            }
            catch (Exception e)
            {
                Console.Write("move: ");
                Console.WriteLine(e.Message);
                Console.WriteLine("Try 'move --help' for more information.");
                return;
            }
            
            GitMover mover = null;
            try
            {
                using (mover = new GitMover(repoDir, options.Source, options.Destination, options.Redirect, options.Continue))
                {
                    mover.Move();
                }
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Error: {0} ", ex.Message);
                Console.ResetColor();

                if (mover != null)
                {
                    mover.Unwind();
                    mover.Dispose();
                }

                // Pause to allow user to view exception message
                Console.WriteLine("\nHit ENTER to exit...");
                Console.ReadLine();
            }

            Console.WriteLine("Done.");
        }
    }
}


