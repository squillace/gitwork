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

        [Option('s', "source", HelpText = "Specifies the root directory of the repo to use; default is current directory.", Required = true, DefaultValue = "")]
        public string Source { get; set; }

        [Option('d', "destination", HelpText = "Specifies the root directory of the repo to use; default is current directory.", Required = true, DefaultValue = "")]
        public string Destination { get; set; }

        [Option('h', "help", HelpText = "Displays this help for \"move\".", Required = false, DefaultValue = false)]
        public bool ShowHelp { get; set; }

        [Option('f', "redirect-file", HelpText = "Indicates that a moved file should be replaced with a redirect file to the new target. Default is false.", Required = false, DefaultValue = false)]
        public bool Redirect { get; set; }

        [Option('c', "continue", HelpText = "Indicates that should a non-fatal error occur, as much work as is possible will complete and the error is reported for follow-up. Default is false.", Required = false, DefaultValue = true)]
        public bool Continue { get; set; }
    }
}
