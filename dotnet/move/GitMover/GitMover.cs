using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSITools
{
    public class GitMover
    {
        private string sourcePattern;
        private string targetPattern;
        private bool redirects;
        private bool commit;

        public GitMover(string v1, string v2)
        {
            this.sourcePattern = v1;
            this.targetPattern = v2;
            ValidateSource();
            
        }

        public GitMover(string source, string target, bool redirects, bool commit)
        {
            this.redirects = redirects;
            this.commit = commit;
        }

        private void ValidateSource()
        {
            if (!File.Exists(sourcePattern))
            {
                throw new Exception("The source file cannot be found: " + sourcePattern);
            }
        }

        public void Move()
        {
            throw new NotImplementedException();
        }

        public void Unwind()
        {
            throw new NotImplementedException();
        }
    }
}
