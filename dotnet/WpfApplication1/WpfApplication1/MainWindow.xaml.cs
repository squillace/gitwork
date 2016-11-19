using Excel;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace WpfApplication1
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        List<string> services;
        DataTable TOCTable;

        public MainWindow()
        {
            InitializeComponent();
            services = new List<string>();

        }
        

        private void treeView_Loaded(object sender, RoutedEventArgs e)
        {
            FileStream stream = File.Open(@"C:\Users\rasquill\Documents\GitHub\gitwork\dotnet\WpfApplication1\WpfApplication1\TOC.xlsx", FileMode.Open, FileAccess.Read);

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
            TOCTable = result.Tables["azure-content-pr"];
  

            ProcessServices(this.listBox, TOCTable);

            //6. Free resources (IExcelDataReader is IDisposable)

            excelReader.Close();
        }

        private void ProcessServices(ListBox listBox, DataTable TOCTable)
        {


            foreach (DataRow row in TOCTable.Rows)
            {
                string temp = row.Field<System.String>("Service");

                if (NotInListBox(temp))
                {
                    listBox.Items.Add(new ListBoxItem() { Content = temp });

                }
                
            }
        }

        private bool NotInListBox(string temp)
        {
            
            foreach (ListBoxItem item in listBox.Items)
            {
                
                if (temp != null && temp != string.Empty && item.Content.ToString().Equals(temp))
                {
                    return false;
                }
            }
            return true;
        }

        private void ProcessRows(TreeView treeView, DataTable TOCTable, string service)
        {

            /*
            2.For each row,
           a. Examine the top level node, make it current node
           b.Test for second level node
              i.If no node, create it
             ii.Make  it current node
                1) Test for third level node
                    a) If no node, create it
                    c) Make it current node
           b. Add node to current node
           */

            treeView.Items.Clear();

            treeView.Items.Add(new TreeViewItem() { Header = "Overview" });
            treeView.Items.Add(new TreeViewItem() { Header = "Get Started" });
            treeView.Items.Add(new TreeViewItem() { Header = "How To" });
            treeView.Items.Add(new TreeViewItem() { Header = "Reference" });
            treeView.Items.Add(new TreeViewItem() { Header = "Related" });
            treeView.Items.Add(new TreeViewItem() { Header = "Resources" });
            foreach (DataRow row in TOCTable.Rows)
            {
                //row.Field<System.String>("Top Node")

                if (row.Field<System.String>("Service") != service)
                    continue;

                if (row.Field<System.String>("Service").Equals("Data Science Process"))
                {
                    ;
                }
                // grab the top level parent node, which rows must have.
                TreeViewItem topNode = FindParentTreeViewNode(treeView.Items, row.Field<System.String>("Top Node"));

                /// not checking for null here, since we already created them.
                if (topNode == null)
                {
                    continue; // TODO: write a log what hasn't been included in the spreadsheet in a toplevel node.              
                }
                if (!row.Field<System.String>("Title").Contains("Add authentication to your"))   
                {
                    string temp = row.Field<System.String>("Title");
                   // continue; // Debug.WriteLine("authentication went there");
                }

                string top = row.Field<System.String>("Top Node");
                string second = row.Field<System.String>("Node 2 TOC") as string;
                string third = row.Field<System.String>("Node 3 TOC") as string;
                string debugtitle = row.Field<System.String>("Title");
                // if there IS a second level in the spreadsheet
                if (row.Field<System.String>("Node 2 TOC") != null && row.Field<System.String>("Node 2 TOC") != string.Empty)
                {
                    // current node is parent.  find out if the node 2 entry is already in the tree
                    TreeViewItem secondNode = FindParentTreeViewNode(topNode.Items, row.Field<System.String>("Node 2 TOC"));

                    // create new treeview if not there yet...
                    if (secondNode == null)
                    {
                        secondNode = new TreeViewItem() { Header = row.Field<System.String>("Node 2 TOC") };
                        // created the node
                        // add second node to parent:
                        topNode.Items.Add(secondNode);

                        // now discover whether the third node in the row
                        if (row.Field<System.String>("Node 3 TOC") != null && row.Field<System.String>("Node 3 TOC") != string.Empty)
                        {
                            // second node is parent
                            // create new node if it isn't there.
                            TreeViewItem thirdNode = FindParentTreeViewNode(secondNode.Items, row.Field<System.String>("Node 3 TOC"));
                            if (thirdNode == null) // if not in treeview yet, create it and add this node to that
                            {
                                thirdNode = new TreeViewItem() { Header = row.Field<System.String>("Node 3 TOC") };
                                // add third to second
                                secondNode.Items.Add(thirdNode);
                                // create and attach leaf node
                                thirdNode.Items.Add(new TreeViewItem() { Header = row.Field<System.String>("Title"), Tag = MakeLink(row) });
                            }
                            else // third node does exist
                            {
                                thirdNode.Items.Add(new TreeViewItem() { Header = row.Field<System.String>("Title"), Tag = MakeLink(row) });
                            }
                        }
                        else // NO
                        {
                            //add here to the second node as a leaf
                            secondNode.Items.Add(new TreeViewItem() { Header = row.Field<System.String>("Title"), Tag = MakeLink(row) });
                        }

                    }
                    else // if the second node is already there
                    {
                        // find if there's a third node in the row
                        TreeViewItem thirdNode = null;
                        if (row.Field<System.String>("Node 3 TOC") != null && row.Field<System.String>("Node 3 TOC") != string.Empty)
                        {
                            thirdNode = FindParentTreeViewNode(secondNode.Items, row.Field<System.String>("Node 3 TOC"));
                            // create new if not there.
                            if (thirdNode == null)
                            {
                                thirdNode = new TreeViewItem() { Header = row.Field<System.String>("Node 3 TOC") };
                                // add third to second
                                secondNode.Items.Add(thirdNode);
                            }
                            else
                            {
                                // create and attach leaf node
                                thirdNode.Items.Add(new TreeViewItem() { Header = row.Field<System.String>("Title"), Tag = MakeLink(row) });
                            }
                            thirdNode.Items.SortDescriptions.Clear();
                            thirdNode.Items.SortDescriptions.Add(new SortDescription("Header", ListSortDirection.Ascending));

                        }
                        else
                        {
                            // there was no third node, so add leaf here
                            secondNode.Items.Add(new TreeViewItem() { Header = row.Field<System.String>("Title"), Tag = MakeLink(row) });
                        }
                    }
                    secondNode.Items.SortDescriptions.Clear();
                    secondNode.Items.SortDescriptions.Add(new SortDescription("Header", ListSortDirection.Ascending));
                }
                else
                {
                    // if second level was null, then attach item
                    string title = row.Field<System.String>("Title");
                    if (title == null)
                    {
                        throw new Exception(row.Field<System.String>("Title"));
                    }
                    topNode.Items.Add(new TreeViewItem() { Header = title, Tag = MakeLink(row) });
                }
                topNode.Items.SortDescriptions.Clear();
                topNode.Items.SortDescriptions.Add(new SortDescription("Header", ListSortDirection.Ascending));

            }
        }

        private string MakeLink(DataRow row)
        {
            if (row.Field<System.String>("Directory (In case you have multiple TOC)") == null || row.Field<System.String>("Directory (In case you have multiple TOC)") == string.Empty)
            {
                return row.Field<System.String>("File (H1 heading)");
            }
            else
            {
                return /*row.Field<System.String>("Directory (In case you have multiple TOC)") + "/" + */ row.Field<System.String>("File (H1 heading)");
            }
        }

        private TreeViewItem FindParentTreeViewNode(ItemCollection viewItemCollection, string nodeName)
        {

            foreach (TreeViewItem node in viewItemCollection)
            {
                if (node == null || node.Header == null)
                {
                    throw new Exception();
                }
                // breadth-first walk
                if (node.Header.ToString().Equals(nodeName))
                {
                    return node;
                }                
            }
            return null;
        }


        private void listBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            var item = ItemsControl.ContainerFromElement(listBox, e.OriginalSource as DependencyObject) as ListBoxItem;
            if (item != null)
            {
                // ListBox item clicked - do some cool things here
                ProcessRows(this.treeView, TOCTable, item.Content.ToString());
            }
        }

        private void listBox_PreviewMouseDown(object sender, MouseButtonEventArgs e)
        {
            var item = ItemsControl.ContainerFromElement(listBox, e.OriginalSource as DependencyObject) as ListBoxItem;
            if (item != null)
            {
                // ListBox item clicked - do some cool things here
                ProcessRows(this.treeView, TOCTable, item.Content.ToString());
            }
            ProcessServices(listBox, TOCTable);
        }

        private void Export_PreviewMouseDown(object sender, MouseButtonEventArgs e)
        {
            string service = (listBox.SelectedItem as ListBoxItem).Content.ToString();
            service = service.ToLower().Replace(' ', '-');

            using (StreamWriter file = new StreamWriter   (service + ".toc.md"))
            {
                foreach (TreeViewItem item in treeView.Items)
                {
                    if (item.Header.Equals("Data Science Process"))
                    {
                        ;
                    }
                    WriteItemDepthFirst(file, item);
                }
            }


        }

        private void WriteItemDepthFirst(StreamWriter file, TreeViewItem item)
        {

            string header = item.Header.ToString();
            if (header == "Azure AD Connect and federation")
            {
                ;
            }

            int parentCount = 0;
            //parentCount = FindTreeLevel(item);
            GetParentCount(item, ref parentCount);
            string hashes = new String('#', parentCount + 1);
            string filePath = "";
            if (item.Tag != null) // if the node has a link
            {
                filePath = item.Tag.ToString().ToLower();
            }
            StringBuilder builder = new StringBuilder(); // if the node is NOT a link
            if (filePath == string.Empty)
            {
                builder.Append(hashes + " " + header);
            }
            else
            {
                builder.Append(hashes + " [" + header + "]("+ filePath + ")");
            }
            file.WriteLine(builder.ToString());

            // call the depth recursion. Make sure there's a terminator here.
            foreach (TreeViewItem child in item.Items)
            {
                WriteItemDepthFirst(file, child);
            }
        }

        private int FindTreeLevel(DependencyObject control)
        {
            var level = -1;
            if (control != null)
            {
                var parent = VisualTreeHelper.GetParent(control);
                while (!(parent is TreeView) && (parent != null))
                {
                    if (parent is TreeViewItem)
                        level++;
                    parent = VisualTreeHelper.GetParent(parent);
                }
            }
            return level;
        }

        private int GetParentCount(TreeViewItem item, ref int count)
        {
            if (!(item.Parent is TreeView))
            {
                ++count;
                GetParentCount(item.Parent as TreeViewItem, ref count);
            }
            return count;
        }
    }

    public class TocItem
    {
        public TocItem()
        {
            this.Children = new ObservableCollection<TocItem>();
        }

        public string Title { get; set; }
        public string TargetFile { get; set; }
        public TocItem Parent { get; set; }

        public string SubDirectory { get; set; }

        public ObservableCollection<TocItem> Children { get; set; }
    }

}

