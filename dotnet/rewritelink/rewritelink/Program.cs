using LibGit2Sharp;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace rewritelink
{
    class Program
    {
        static void Main(string[] args)
        {
            Replacements replace = new Replacements();
            replace.Run();



        }
    }
}
