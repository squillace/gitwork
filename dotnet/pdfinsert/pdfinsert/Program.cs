using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace pdfinsert
{
    class Program
    {
        static void Main(string[] args)
        {
            string linkfile = "azure-docs-pr-pdf-links.txt";
            string repo = @"C:\users\rasquill\documents\github\azure-docs-pr\articles\";
            File.Exists(linkfile);
            string line;

            StreamReader PDFfiles = new StreamReader(linkfile);

            while ((line = PDFfiles.ReadLine()) != null)
            {
                // Console.WriteLine(line);
                string dir; // = repo + line.Substring(line.LastIndexOf("live/") + 1);
                Match dirmatch = Regex.Match(line, @"live/.*(?=.pdf)");
                if (dirmatch.Success)
                {
                    dir = repo + dirmatch.Value; // dir.Replace(".pdf", string.Empty);
                    dir = dir.Replace(@"live/", @"");
                    dir = dir.Replace(@"/", @"\");
                    if (!Directory.Exists(dir))
                    {
                        Console.WriteLine(dir);
                        Console.WriteLine(line);
                    }
                    else
                    {
                        //Console.WriteLine("EXISTS: " + dir);
                        string indexFile = dir + @"\index.md";

                        string replacement = line;

                        if (File.Exists(indexFile))

                        {
                            Regex pattern = new Regex("<div class=\"downloadHolder\">.+?href=\"https://msdn.microsoft.com/\"", RegexOptions.Singleline);
                            string htmlmatch = pattern.Replace(File.ReadAllText(indexFile), "<div class=\"downloadHolder\">\n    <a href=\""  + replacement + "\"");
                            //File.WriteAllText(indexFile, htmlmatch);
                            /*
                            if (pattern.Success)
                            {
                                Console.WriteLine(htmlmatch.Value);
                                Console.WriteLine(indexFile);
                            }
                            */
                        }
                    }
                }

            }
            Console.ReadLine();

            PDFfiles.Close();
        }
    }
}
