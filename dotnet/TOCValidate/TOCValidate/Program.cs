using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LibGit2Sharp;
using System.Text.RegularExpressions;
using System.IO;
using System.Collections.Specialized;


/*
---
title: Log in to Azure from the CLI | Microsoft Azure
description: Connect to your Azure subscription from the Azure Command-Line Interface (Azure CLI) for Mac, Linux, and Windows
editor: tysonn
manager: timlt
documentationcenter: ''
author: dlepow
services: virtual-machines-linux,virtual-network,storage,azure-resource-manager
tags: azure-resource-manager,azure-service-management

ms.service: multiple
ms.workload: multiple
ms.tgt_pltfrm: vm-multiple
ms.devlang: na
ms.topic: article
ms.date: 10/04/2016
ms.author: danlep

---


    ALGORITHM:

    	1. Grab the articles working directory.
	2. Get a list of every single file in the reading repo.
	3. For each file
		a. Is it in a toc?
			i. Yes: remove it from the list
			ii. No: move to next file
	4. Write out what files are not in tocs
	5. Write out the title of the file
	6. Write out the service-slug
    7. Write out the ms.author


*/
namespace TOCValidate
{
    class Validator
    {
        private string[] args;
        string originalRepo;
        string migrationRepo;
        List<string> Tocs;
        List<string> Files;
        Repository MigrationRepo;

        public Validator(string[] args)
        {
            this.args = args;
            originalRepo = args[0];
            migrationRepo = args[0];
            this.Run();

        }

        private void Run()
        {
            using (MigrationRepo = new Repository(migrationRepo /*, new RepositoryOptions() { WorkingDirectoryPath = this.originalRepo} */))
            {
                Console.WriteLine(MigrationRepo.Info.WorkingDirectory);
                MigrationRepo.Checkout("master");

                Tocs = (from t in MigrationRepo.Index
                           where t.Path.Contains("TOC.md")
                           select t.Path).ToList<string>();

                Files = (from f in MigrationRepo.Index
                            where f.Path.Contains(".md") && !f.Path.Contains("TOC.md") && !f.Path.Contains(@"includes\")
                            select f.Path).ToList<string>();

                FindFilesInTocs();

                StringCollection files = new StringCollection();
                foreach (string item in Files)
                {
                    StringBuilder builder = new StringBuilder();
                    //Console.WriteLine(item);
                    string filePath = MigrationRepo.Info.WorkingDirectory + item;
                    string fileContent = File.ReadAllText(filePath);
                    Match title = Regex.Match(fileContent, @"(?<=#{1}\s).*");
                    builder.Append("\"" + item + "\"");
                    if (title.Success)
                    {
                        builder.Append(",\"" + title.Value.Trim() + "\"");
                    }
                    Match author = Regex.Match(fileContent, @"(?<=ms.author:).*");
                    if (author.Success)
                    {
                        builder.Append(",\"" + author.Value.Trim() + "\"");
                    }
                    builder.Append(",\"" + "# [" + title.Value.Trim() + "](" + item.Substring(item.LastIndexOf(@"\") + 1) + ")\"");
                    files.Add(builder.ToString());
                }

                foreach (string output in files)
                {
                    Console.WriteLine(output);
                }
                Console.WriteLine("count of files not removed: " + Files.Count);
                //Console.ReadLine();
            }
        }

        private void FindFilesInTocs()
        {
            List < string > templist = this.Files.ToList<string>();
            foreach (string file in templist)
            {
                if (IsInTOC(file))
                {
                    // can't iterate over enumerations that have been modified. Have to do someting different. 
                    this.Files.RemoveAll(entry => entry.Equals(file));
                }
            }
        }

        private bool IsInTOC(string file)
        {
            foreach (string toc in this.Tocs)
            {
                Match results = Regex.Match(File.ReadAllText(MigrationRepo.Info.WorkingDirectory + toc), file.Substring(file.LastIndexOf(@"\") + 1));
                if (!results.Success)
                {
                    continue;
                }
                else
                    return true;
            }
            return false;
        }

        static void Main(string[] args)
        {
            Validator validator = new Validator(args);

        }
    }
}
