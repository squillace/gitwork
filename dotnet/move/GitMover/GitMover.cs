using LibGit2Sharp;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
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

        public string repoWorkingRoot { get; private set; }

        private GitMover() { }

        public GitMover(string repoRootDir, string source, string target, bool redirects, bool commit)
        {
            this.repoWorkingRoot = repoRootDir;
            this.redirects = redirects;
            this.commit = commit;
            this.sourcePattern = source;
            this.targetPattern = target;
            this.repo = new Repository(repoRootDir);
        }

        private void ValidateSource()
        {
            if (!File.Exists(repo.Info.WorkingDirectory + sourcePattern))
            {
                throw new Exception("The source file cannot be found: " + sourcePattern);
            }

        }

        public void Move()
        {
            ValidateSource();
            MoveFile();
            /*
            RewriteInboundLinks();
            RewriteIncludeLinks();
            Commit();
            WriteRedirectFile();
            */
            
        }

        private void MoveFile()
        {
            repo.Move(sourcePattern, targetPattern);
            MoveMedia();
        }

        // Media moves always lowercase the new files.
        // Does not assume that media files are in the proper location relative to this file.
        private void MoveMedia()
        {
            Dictionary<string, string> mediaLinkMap = GetMediaLocations();

            // Move them
            foreach (KeyValuePair<string, string> mediaFileEntry in mediaLinkMap)
            {
                repo.Move(mediaFileEntry.Key.ToString(), mediaFileEntry.Value.ToString());
            }

            // now commit so we can continue working with them.
            Signature author = new Signature("squillace", "ralph@squillace.com", DateTime.Now);
            repo.Commit("Files moved; rewriting internal and external links.", author, author);
            RewriteInternalMediaLinks(mediaLinkMap);
        }

        /// <summary>
        /// For each media file, ensure that the internal links are fixed properly even
        /// though they should already be fine.
        /// </summary>
        /// <param name="mediaLinkMap"></param>
        private void RewriteInternalMediaLinks(Dictionary<string, string> mediaLinkMap)
        {

            // find the new file and load it
            // TODO: why doesn't this load? are the files NOT there? Do we need to fetch this from 
            // the repo as a blob?
            string newFileText = File.ReadAllText(repo.Info.WorkingDirectory + targetPattern);
            string mediaDirectory =
                @"media\"
                + Path.GetFileNameWithoutExtension(targetPattern)
                + @"\";
             

            // for each media file referenced, grab precisely the link from the file and replace it with the new link
            // in the form: media\<new markdown file name>\<same media file name>

            var imagelinks = Regex.Matches(
                File.ReadAllText(repo.Info.WorkingDirectory + targetPattern),
                @"(?<=\!)\[.+?\]\(.+?\)"
            );
            foreach (Match currentInternalMediaString in imagelinks)
            {
                // relative path from the original file directory
                string mediaLink = (Regex.Match(currentInternalMediaString.Value, @"(?<=\]\().+?(?=\))")).Value;
                string replacementHTML = newFileText.Replace(mediaLink, mediaDirectory + Path.GetFileName(currentInternalMediaString.Value));
                ;
            }

            foreach (KeyValuePair<string,string> mediaKeyPair in mediaLinkMap)
            {



            }
        }

        /// <summary>
        /// Returns a dictionary of the source media files from the moved file and their new
        /// resulting locations as strings ready for moving.
        /// </summary>
        /// <returns></returns>
        private Dictionary<string, string> GetMediaLocations()
        {
            Dictionary<string, string> imageLocationList = new Dictionary<string, string>();
            // image format:
            // This gets image links 

            /*
                .bmp
                .gif
                .jpg
                .pdf
                .png
                .svg
                */

            var imagelinks = Regex.Matches(
                File.ReadAllText(repo.Info.WorkingDirectory + targetPattern), 
                @"(?<=\!)\[.+?\]\(.+?\)"
            );

            foreach (Match item in imagelinks)
            {
                // relative path from the original file directory
                string searchPath = (Regex.Match(item.Value, @"(?<=\]\().+?(?=\))")).Value;

                // original directory and file name
                string sourceDir = Path.GetDirectoryName(sourcePattern);
                string filename = Path.GetFileName(sourcePattern);

                string sourceMediaPath = Path.GetFullPath(
                    Path.Combine(repo.Info.WorkingDirectory + sourceDir, searchPath))
                    .Replace(repo.Info.WorkingDirectory, ""
                    );

                // make sure you can find it
                var mediaIndexEntry = from m in repo.Index
                                      where m.Path.Contains(sourceMediaPath)
                                      select m;

                if (mediaIndexEntry.Count() != 1)
                {
                    throw new Exception("Strange: " + sourceMediaPath + " has more than one entry.");
                }

                string realSourcePath = mediaIndexEntry.First().Path;
                string targetMediaPath = Path.GetDirectoryName(targetPattern)
                        + @"\media\"
                        + Path.GetFileNameWithoutExtension(targetPattern).ToLower()
                        + Path.GetFileName(realSourcePath).ToLower();

                imageLocationList.Add(realSourcePath, targetMediaPath);

            }
            return imageLocationList;
        }

        public void Unwind()
        {
            // Force reset the branch to what it was.
            this.Dispose();
        }

        public void Dispose()
        {
            repo.Dispose();
        }
    }
}
