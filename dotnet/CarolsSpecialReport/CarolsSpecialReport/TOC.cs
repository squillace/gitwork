using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Controls;

namespace CarolsSpecialReport
{
    public class TOC
    {
        TreeView internalTOC;
        TreeViewItem currentItem;

        public TOC(string filepath)
        {
            string line;
            StreamReader file = new StreamReader(filepath);

            while ((line = file.ReadLine()) != null)
            {
                Match heading = Regex.Match(line, @"^#{1,}");
                if (heading.Captures.Count == 0)
                {
                    continue;
                }
                Match title = Regex.Match(line, @"(?<=\[).*(?=\])");
                string titlestring = "";
                if (title.Success)
                {
                    titlestring = title.Value.Trim();
                }
                else {
                    titlestring = Regex.Match(line, @" .*").Value.Trim();
                }
                Match link = Regex.Match(line, @"\(.*\)");
                Console.WriteLine(heading.Value.Count());
                Console.WriteLine(titlestring);
                Console.WriteLine(link);
                Console.ReadLine();

                
            }
            file.Close();
        }

    }
}
