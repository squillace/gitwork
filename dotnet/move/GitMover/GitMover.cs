using LibGit2Sharp;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSITools
{
    public class GitMover : IDisposable
    {
        private string sourcePattern;
        private string targetPattern;
        private bool redirects;
        private bool commit;
        Repository repo;

        private GitMover() { }

        public GitMover(string source, string target, bool redirects, bool commit)
        {
            this.redirects = redirects;
            this.commit = commit;
            this.sourcePattern = source;
            this.targetPattern = target;
            this.repo = new Repository(Directory.GetCurrentDirectory());
        }

        private void ValidateSource()
        {
            if (!File.Exists(sourcePattern))
            {
                throw new Exception("The source file cannot be found: " + sourcePattern);
            }
            if (repo.Info.Path != repo.Info.WorkingDirectory)
            {
                throw new Exception("Execute this command at the root of the repository.");
            }
        }

        public void Move()
        {
            ValidateSource();
            
        }

        public void Unwind()
        {
            ;
        }

        public void Dispose()
        {
            ;
        }
    }
}
