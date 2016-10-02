using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;

using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace docstoc
{
    public partial class Form1 : Form
    {

        string workingTocFile = "";
        string tocContents = "";

        public Form1()
        {
            InitializeComponent();
        }

        private void openToolStripMenuItem_Click(object sender, EventArgs e)
        {
            using (var selectFileDialog = new OpenFileDialog())
            {
                selectFileDialog.Title = "Select the JSON Toc file to import...";
                if (selectFileDialog.ShowDialog() == DialogResult.OK)
                {
                    this.workingTocFile = selectFileDialog.FileName;
                    tocContents = File.ReadAllText(this.workingTocFile);
                    loadTOC(this.treeView1.Nodes);

                }
            }
        }

        private void loadTOC(TreeNodeCollection nodes)
        {
            using (StreamReader file = new StreamReader(this.workingTocFile))
            {
                var line = "";
                TreeNode currentParent;
                while ((line = file.ReadLine()) != null)
                {
                    // read line; always starts with the lead node, # so we capture it

                    string rootHeader = @"^#{1} .*";
                    string titleRegex = @"(?<=# ).*"; // @"(?<=\[).+(?=\])";
                    string targetPathRegex = @"(?<=\]\().+(?=\))";

                    if (Regex.IsMatch(line, rootHeader))
                    {
                        string match = Regex.Match(line, titleRegex).Value;
                        string secondMatch = Regex.Match(line, @"(?<=# ).*").Value;
                        TreeNode node;
                        if (Regex.IsMatch(line, @"(?<=\[).+(?=\])"))
                        {
                            // we are a linked H1
                            node = new TreeNode(Regex.Match(line, @"(?<=\[).+(?=\])").Value);
                            node.Tag = Regex.Match(line, targetPathRegex);
                            node.ToolTipText = node.Tag.ToString();
                            
                        }
                        else 
                            // we are a standalone H1
                            node = new TreeNode(Regex.Match(line, titleRegex).Value);
                        this.treeView1.Nodes.Add(node);
                    }
                    if (line.StartsWith(@"##"))
                    {
                        //currentParent.Nodes.Add(new TreeNode(line));
                    }
                    

                }
            }

        }

        private void treeView1_AfterSelect(object sender, TreeViewEventArgs e)
        {
            if (e.Node.Tag == null)
            {
                return;
            }
            DirectoryInfo dirInfo = new FileInfo(workingTocFile).Directory;
            FileInfo currentFile = dirInfo.GetFiles(e.Node.Tag.ToString()).FirstOrDefault();
            this.richTextBox1.Text = currentFile.OpenText().ReadToEnd();
            
        }
    }
}
