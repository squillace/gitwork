using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace buildtoc
{
    public class TOCItem : List<TOCItem>
    {
        public TOCItem(ref TOCItem parent, DataRow row)
        {
            ID = row.Field<System.String>("ID");
            // TODO: Console.WriteLine("{0}: {1}", row.Table.Columns["TOC Files"], row.Field<System.Double>("TOC Files"));
            FileName = row.Field<System.String>("File (H1 heading)");
            Title = row.Field<System.String>("Title");
            Service = row.Field<System.String>("Service");
            ServiceSlug = row.Field<System.String>("Service Slug");
            Author = row.Field<System.String>("Author");
            Pillar = row.Field<System.String>("Pillar");
            Directory = row.Field<System.String>("Directory (In case you have multiple TOC)");
            RootNode = row.Field<System.String>("Top Node");
            Node2 = row.Field<System.String>("Node 2 TOC");
            Node3 = row.Field<System.String>("Node 3 TOC");
            //row.Field<System.String>("Comments/Notes");
            parent.Add(this);

            /*
             * Place yourself algorithm:
             * 1. you're given a parent node. Find the root node to which you belong
             * 2. if node 3 is null, then: is NOT in the tree, add it
             * 2. b. if node 3 if node 3 is not in the tree, add it, and then you.
             * 2. c. if node 3 
             
            foreach (TOCItem item in parent.ToList<TOCItem>())
            {
                if (item.Title.Equals(this.Title)) // we found the root node for this item
                {
                  if (this.Node2.Equals(String.Empty) || this.Node2 == null)
                        item.Add(this);
                    
                  foreach (TOCItem subnode in item.ToList<TOCItem>())
                    {
                        if (subnode.Title.Equals(this.Node2)) // we found the subnode for this item
                        {
                            foreach (TOCItem thirdnode in subnode.ToList<TOCItem>())
                            {
                                if (thirdnode.Title.Equals(this.Node3))
                                    thirdnode.Add(this);
                            }
                        }
                        else
                        {
                            // add here
                            subnode.Add(this);
                        }
                    }
                    
                }
                else
                    throw new Exception("couldn't find the " + item.Title + " in the root of the TOC for " + this.Title);
            }
            */
            
        }

        public TOCItem(string title)
        {
            this.Title = title;
        }

        public string Author { get; private set; }
        public string Directory { get; private set; }
        public string FileName { get; private set; }
        public string ID { get; private set; }
        public string Node2 { get; private set; }
        public string Node3 { get; private set; }
        public string Pillar { get; private set; }
        public string RootNode { get; private set; }
        public string Service { get; private set; }
        public string ServiceSlug { get; private set; }
        public string Title { get; private set; }

        /*
ID, type: System.String

TOC Files, type: System.Double
File (H1 heading), type: System.String
Title, type: System.String
Service, type: System.String
Service Slug, type: System.String
Author, type: System.String
Pillar, type: System.String
Directory (In case you have multiple TOC), type: System.String
Top Node, type: System.String
Node 2 TOC, type: System.String
Node 3 TOC, type: System.String
Comments/Notes, type: System.String
*/
    }
}
