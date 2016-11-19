using Excel;
using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Controls;



namespace buildtoc
{
    class Program
    {

        static void Main(string[] args)
        {


            FileStream stream = File.Open(args[0], FileMode.Open, FileAccess.Read);

            //Choose one of either 1 or 2
            //1. Reading from a binary Excel file ('97-2003 format; *.xls)
            // # IExcelDataReader excelReader = ExcelReaderFactory.CreateBinaryReader(stream);

            //2. Reading from a OpenXml Excel file (2007 format; *.xlsx)
            IExcelDataReader excelReader = ExcelReaderFactory.CreateOpenXmlReader(stream);


            //Choose one of either 3, 4, or 5
            //3. DataSet - The result of each spreadsheet will be created in the result.Tables
            //# DataSet result = excelReader.AsDataSet();

            //4. DataSet - Create column names from first row
            // works fine
            excelReader.IsFirstRowAsColumnNames = true;
            DataSet result = excelReader.AsDataSet();
            DataTable TOCTable = result.Tables["azure-content-pr"];

            MakeTreeViewItemTree(result, TOCTable);

            TOC toc = new TOC();
            /*
            foreach (DataColumn column in TOCTable.Columns)
            {
                //Console.WriteLine("{0}, type: {1}", column.ColumnName, column.DataType);
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
            /*
            }
            */




            foreach (DataRow row in TOCTable.Rows)
            {
                if (row.Field<System.String>("Service") != "App Service")
                    continue;


               // ID = row.Field<System.String>("ID");
                /// TODO: Console.WriteLine("{0}: {1}", row.Table.Columns["TOC Files"], row.Field<System.Double>("TOC Files"));
                /*            FileName = row.Field<System.String>("File (H1 heading)");
                            Title = row.Field<System.String>("Title");
                            Service = row.Field<System.String>("Service");
                            ServiceSlug = row.Field<System.String>("Service Slug");
                            Author = row.Field<System.String>("Author");
                            Pillar = row.Field<System.String>("Pillar");
                            Directory = row.Field<System.String>("Directory (In case you have multiple TOC)");
                            RootNode = row.Field<System.String>("Top Node");
                            Node2 = row.Field<System.String>("Node 2 TOC");
                            Node3 = row.Field<System.String>("Node 3 TOC");
                */
                StringBuilder builder = new StringBuilder();
                builder.Append("# [" + row.Field<System.String>("Top Node") + "]");
                if (row.Field<System.String>("Node 2 TOC") != null && !row.Field<System.String>("Node 2 TOC").Equals(String.Empty))
                {
                    builder.Insert(0, '#');
                    builder.Append("[" + row.Field<System.String>("Node 2 TOC") + "]");
                }
                if (row.Field<System.String>("Node 3 TOC") != null && !row.Field<System.String>("Node 3 TOC").Equals(String.Empty))
                {
                    builder.Insert(0, '#');
                    builder.Append("[" + row.Field<System.String>("Node 3 TOC") + "]");
                }
                builder.Append("[" + row.Field<System.String>("Title") + "]");
                builder.Append("(" + row.Field<System.String>("File (H1 heading)") + ")");
                //Console.WriteLine(builder.ToString());

                //6. Free resources (IExcelDataReader is IDisposable)

                excelReader.Close();
            }
            }

        private static void MakeTreeViewItemTree(DataSet result, DataTable tOCTable)
        {
            throw new NotImplementedException();
        }

        private void FillTree(DataSet result, DataTable tOCTable, TreeView tvMain)
        {
            tvMain.ItemTemplate = GetHeaderTemplate();
            tvMain.ItemContainerGenerator.StatusChanged +=
                new EventHandler(ItemContainerGenerator_StatusChanged);

            foreach (WorldArea area in _list)
            {
                tvMain.Items.Add(area);
            }
        }

        void ItemContainerGenerator_StatusChanged(object sender, EventArgs e)
        {
            if (tvMain.ItemContainerGenerator.Status == GeneratorStatus.ContainersGenerated)
            {
                foreach (WorldArea area in _list)
                {
                    TreeViewItem item =
                (TreeViewItem)tvMain.ItemContainerGenerator.ContainerFromItem(area);
                    if (item == null) continue;
                    item.IsExpanded = true;
                    if (item.Items.Count == 0)
                    {

                        foreach (Country country in area.Countries)
                        {
                            item.Items.Add(country);
                        }
                    }
                }
            }
        }
    }
    }
