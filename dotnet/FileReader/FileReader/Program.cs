using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FileReader
{
    class Program
    {
        static void Main(string[] args)
        {
            var temp = 
                File.ReadAllText(@"C:\users\rasquill\documents\github\azure-docs-pr\articles\virtual-machines\virtual-machines-linux-quick-create-portal.md");
            Console.WriteLine(temp);
            Console.ReadLine();
        }
    }
}
