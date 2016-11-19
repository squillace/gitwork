using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace migratetoc
{
    class Program
    {

        /// <summary>
        /// Tages two arguments, the root of two repositories that are presumed to map perfectly. 
        /// The tool will check whether this is true or not at the specified level by looking for the articles directory,
        /// but otherwise does no checking.
        /// </summary>
        /// <param name="args"></param>
        static void Main(string[] args)
        {
            string sourceRepo = args[0];
            string targetRepo = args[1];

            ValidateRepoArguments(sourceRepo, targetRepo);


        }

        private static void ValidateRepoArguments(string sourceRepo, string targetRepo)
        {
            if (
                Directory.Exists(sourceRepo) 
                && Directory.Exists(targetRepo) 
                && Directory.Exists(sourceRepo + "/articles") 
                && Directory.Exists(targetRepo + "/articles")
                )
            {
                return;
            }
            else
                throw new Exception("Either the directories do not exist, or the articles subdirectories do not exist.");
        }
    }
}
