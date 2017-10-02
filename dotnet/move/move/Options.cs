using System;
using System.Collections.Generic;
using System.Linq;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using CommandLine;

namespace links
{
    internal class Options
    {
        [Option('r', "repo-directory", HelpText = "Specifies the root directory of the repo to use; default is current directory.", Required = false, DefaultValue = "")]
        public string RepoDir { get; set; }

        [Option('s', "source", HelpText = "The current path of the file to be moved, relative to the repo-directory (e.g. articles/batch/myarticle.md).", Required = false, DefaultValue = "")]
        public string Source { get; set; }

        [Option('d', "destination", HelpText = "The new path for the file, relative to the repo-directory (e.g. articles/batch/newdir/myarticle.md).", Required = false, DefaultValue = "")]
        public string Destination { get; set; }

        [Option('h', "help", HelpText = "Displays this help for \"move\".", Required = false, DefaultValue = false)]
        public bool ShowHelp { get; set; }

        [Option('f', "redirect-file", HelpText = "Indicates that a moved file should be replaced with a redirect file to the new target. Default is false.", Required = false, DefaultValue = false)]
        public bool Redirect { get; set; }

        [Option('c', "continue", HelpText = "Indicates that should a non-fatal error occur, as much work as is possible will complete and the error is reported for follow-up. Default is true.", Required = false, DefaultValue = true)]
        public bool Continue { get; set; }

        [Option('t', "do-commit", HelpText = "Specifies whether changes should be automatically committed via 'git commit'. Default is false.", Required = false, DefaultValue = false)]
        public bool DoCommit { get; set; }
    }
}
