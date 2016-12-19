using LibGit2Sharp;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using NDepend.Path;

namespace CSITools
{
    /// <summary>
    /// The GitMover class provides methods that:
    /// 1. Takes an existing file and a new target file path.
    /// 2. Rewrites all inbound links to the current file to point to the new file.
    /// 3. Rewrites all internal include and media links to where they **should** be.
    /// 4. Moves the source file to the target location in git.
    /// 5. Moves all media files from the original location to the new, proper location. 
    /// 6. If the redirects argument is true, GitMover will replace the old file location with 
    /// a new file containing only the redirect_url: key with the new file location as the target value.
    /// </summary>
    /// <remarks>
    /// <para>The GitMover class depends upon both Lib2GitSharp and also NDepent.Path, the former for git activity and 
    /// the latter to provide relative directory path functionality. As a result, the relevant .dlls must also be distributed with 
    /// the executable. 
    /// </para>
    /// <para>
    /// Some side effects noted: to view the results on the command line, you can of course git status, but
    /// to review the changes made use "git diff --cached", which will review the added and moved files.
    /// </para>
    /// </remarks>
    public class GitMover : IDisposable
    {
        private string sourcePattern;
        private string targetPattern;
        private bool redirects;
        private bool commit;
        Repository repo;
        private string originalFileContents;

        public string repoWorkingRoot { get; private set; }

        private GitMover() { }

        /// <summary>
        /// Creates a GitMover, which can move one file to a new location along with all attendant
        /// changes required. 
        /// </summary>
        /// <param name="repoRootDir"></param>
        /// <param name="source">The target file path relative to the root of a repo. Can be either '\' or '/' usage.</param>
        /// <param name="target">The path of the new file relative to the root of a repo. Can be either '\' or '/' usage.</param>
        /// <param name="redirects">If true, creates a redirect file for the moved file. Default is false.</param>
        /// <param name="commit">If true, commits the changes.</param>
        public GitMover(string repoRootDir, string source, string target, bool redirects, bool commit)
        {
            this.repoWorkingRoot = repoRootDir;
            this.redirects = redirects;
            this.commit = commit;
            this.sourcePattern = source.Replace(@"/", @"\");
            this.targetPattern = target.Replace(@"/", @"\");
            this.repo = new Repository(repoRootDir);
            var temp = new FileInfo(repoRootDir + sourcePattern);
            this.originalFileContents = temp.OpenText().ReadToEnd();

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
            /*
             * Note on internal implementation. 
             * Depending upon how many times you want to use the tool in the same "git session", 
             * you may want one or several million commits to result. 
             * The default behavior is to make all cross repo-changes first, then rewrite 
             * include and media links inside the file, and finally move the file, adding any 
             * redirect as specified. 
             * As a result, the below calls need to happen in this order. There ARE other orders
             * that can work for this use-case, but this is the current implementation. 
             * TODO: make each call idempotent, resulting only in the same end situation no matter how it is used. 
             * As that's not done yet -- I'm busy! -- these methods are **internal**, requiring only that external callers
             * invoke Move to make all the work happen.
             */

            ValidateSource();
            RewriteInboundLinks();
            RewriteIncludeLinks();
            MoveMedia();
            MoveFile();
            WriteRedirectFile();
            CommitChanges();

        }

        private void CommitChanges()
        {
            // Signature signer = new Signature();
            repo.Commit("Moved " + sourcePattern + " to " + targetPattern);
        }

        private void WriteRedirectFile()
        {
            if (redirects)
            {
                string tempRedirectString = targetPattern.Replace(@"articles\", "").Replace(@"\", @"/");
                StreamWriter redirectFile = File.CreateText(repo.Info.WorkingDirectory + sourcePattern);
                redirectFile.WriteLine("---");
                redirectFile.WriteLine("redirect_url: /azure/" + tempRedirectString);
                redirectFile.WriteLine("---");
                redirectFile.Close();

                repo.Stage(repo.Info.WorkingDirectory + sourcePattern);
                
            }
        }

        /// <summary>
        /// Rewrites any include links by examining the source file and calculating and replacing 
        /// all links to include files in the file with new ones based upon whether a directory was 
        /// changed or not.
        /// </summary>
        private void RewriteIncludeLinks()
        {
            // TODO: [!INCLUDE [support-disclaimer](../../../../includes/support-disclaimer.md)]
            string newFileDirectoryPath = Path.GetDirectoryName(repo.Info.WorkingDirectory + targetPattern);

            // for each media file referenced, grab precisely the link from the file and replace it with the new link
            // in the form: media\<new markdown file name>\<same media file name>
            string regexText = @"\!INCLUDE {0,1}\[.+?\]\(.+?" + Path.GetFileName(sourcePattern);
            var includeLinks = Regex.Matches(
                File.ReadAllText(repo.Info.WorkingDirectory + sourcePattern),
                @"\!INCLUDE {0,1}\[.+?\]\(.+?\)"
            );

            foreach (Match currentInternalMediaString in includeLinks)
            {
                string oldIncludeRelativeLink = (Regex.Match(currentInternalMediaString.Value, @"(?<=\]\().+?(?=\))")).Value;

                // GetRelativePath takes an absolute path to a file and an absolute path to a directory
                // and returns the relative path from the latter to the former.
                string linkFileName = Path.GetFileName(oldIncludeRelativeLink);
                var includeFile = (from i in repo.Index
                                  where
                                  (
                                  i.Path.Contains(@"includes\")
                                  && i.Path.EndsWith(linkFileName)
                                  )
                                  select i).FirstOrDefault();

                var fromAbsoluteDirectoryPath = (newFileDirectoryPath + Path.DirectorySeparatorChar.ToString()).ToAbsoluteDirectoryPath();
                var targetIncludeAbsoluteFilePath =
                    (Path.GetFullPath(repo.Info.WorkingDirectory + includeFile.Path)).ToAbsoluteFilePath();

                //      var relativeFilePath2 = absoluteFilePath2.GetRelativePathFrom(absoluteDirectoryPath);
                string newIncludeRelativeLink = targetIncludeAbsoluteFilePath.GetRelativePathFrom(fromAbsoluteDirectoryPath).ToString();
                if (newIncludeRelativeLink.StartsWith(@".\"))
                {
                    newIncludeRelativeLink = newIncludeRelativeLink.Remove(0, 2);
                }

                string replacementHTML = (File.ReadAllText(repo.Info.WorkingDirectory + sourcePattern))
                    .Replace(oldIncludeRelativeLink, newIncludeRelativeLink);
                // go back to linux links:
                replacementHTML = replacementHTML.Replace(@"\", @"/");
                ;
                File.WriteAllText(repo.Info.WorkingDirectory + sourcePattern, replacementHTML);
            }

        }

        private void RewriteInboundLinks()
        {
            string originalDirName = Path.GetDirectoryName(repo.Info.WorkingDirectory + sourcePattern);
            string originalFileName = Path.GetFileName(sourcePattern);
            string targetDirName = Path.GetDirectoryName(repo.Info.WorkingDirectory + targetPattern);
            string targetFileName = Path.GetFileName(targetPattern);

            var repoFiles = from i in repo.Index
                            where i.Path.Contains(".md")
                            && (i.Path.Contains("articles")
                            || i.Path.Contains("includes"))
                            select i;

            Regex justFilePattern = new Regex(originalFileName);

            foreach (IndexEntry file in repoFiles)
            {
                //  if it has a match: focus!
                if (justFilePattern.IsMatch(File.ReadAllText(repo.Info.WorkingDirectory + file.Path)))
                {
                    // get all matches in links
                    var oldInboundLinks = Regex.Matches(
                        File.ReadAllText(repo.Info.WorkingDirectory + file.Path),
                        @"(?<=\]\()\S*" + originalFileName
                    );


                    var targetAbsoluteDirectoryPath = (
                        Path.GetDirectoryName(repo.Info.WorkingDirectory + file.Path) + Path.DirectorySeparatorChar.ToString()).ToAbsoluteDirectoryPath();
                    var targetAbsoluteLinkPath =
                        (repo.Info.WorkingDirectory + targetPattern).ToAbsoluteFilePath();

                    //      var relativeFilePath2 = absoluteFilePath2.GetRelativePathFrom(absoluteDirectoryPath);
                    // Make relative link to new location
                    string newInboundLink = targetAbsoluteLinkPath.GetRelativePathFrom(targetAbsoluteDirectoryPath).ToString();
                    if (newInboundLink.StartsWith(@".\"))
                    {
                        newInboundLink = newInboundLink.Remove(0, 2);
                    }
                    newInboundLink = newInboundLink.Replace(@"\", @"/");


                    // for each link match, replace that with the new, relative link.
                    foreach (Match inboundLinkMatch in oldInboundLinks)
                    {
                        Regex currentRegex = new Regex(inboundLinkMatch.Value);
                        string replaceText = currentRegex.Replace(File.ReadAllText(repo.Info.WorkingDirectory + file.Path), newInboundLink);
                        File.WriteAllText(repo.Info.WorkingDirectory + file.Path, replaceText);
                        repo.Stage(file.Path);
                    }
                }
             }
        }


        private void MoveFile()
        {
            if (!Directory.Exists(Path.GetDirectoryName(repo.Info.WorkingDirectory + targetPattern)))
            {
                Directory.CreateDirectory(Path.GetDirectoryName(repo.Info.WorkingDirectory + targetPattern));
            }
            repo.Move(sourcePattern, targetPattern);
        }

        // Media moves always lowercase the new files.
        // Does not assume that media files are in the proper location relative to this file.
        private void MoveMedia()
        {
            Dictionary<string, string> mediaLinkMap = GetMediaLocations();

            // Move them
            foreach (KeyValuePair<string, string> mediaFileEntry in mediaLinkMap)
            {
                string oldPath = mediaFileEntry.Key.ToString(); 
                string newPath = mediaFileEntry.Value.ToString(); 

                // make sure the moving directory exists, or EVERYTHING WILL FAIL.
                if (!Directory.Exists(Path.GetDirectoryName(newPath)))
                {
                    Directory.CreateDirectory(Path.GetDirectoryName(newPath));
                }

                if (File.Exists(repo.Info.WorkingDirectory + oldPath) && Directory.Exists(Path.GetDirectoryName(newPath)))
                {
                    try
                    {
                        repo.Move(oldPath, newPath);
                    }
                    catch (Exception)
                    {
                        throw;
                    }
                }
            }

            // now commit so we can continue working with them.
            Signature author = new Signature("squillace", "ralph@squillace.com", DateTime.Now);

            // repo.Commit("Files moved; rewriting internal and external links.", author, author);
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

            string mediaDirectory =
                @"media\"
                + Path.GetFileNameWithoutExtension(targetPattern)
                + @"\";

            // for each media file referenced, grab precisely the link from the file and replace it with the new link
            // in the form: media\<new markdown file name>\<same media file name>

            var imagelinks = Regex.Matches(
                File.ReadAllText(repo.Info.WorkingDirectory + sourcePattern),
                @"(?<=\!)\[.+?\]\(.+?\)"
            );

            foreach (Match currentInternalMediaString in imagelinks)
            {
                string oldMediaLink = (Regex.Match(currentInternalMediaString.Value, @"(?<=\]\().+?(?=\))")).Value;

                // GetRelativePath takes an absolute path to a file and an absolute path to a directory
                // and returns the relative path from the latter to the former.
                string mediaFileName = Path.GetFileName(oldMediaLink);
                var targetAbsoluteDirectoryPath = (Path.GetDirectoryName(repo.Info.WorkingDirectory + targetPattern) + Path.DirectorySeparatorChar.ToString()).ToAbsoluteDirectoryPath();
                var targetAbsoluteMediaPath =
                    (targetAbsoluteDirectoryPath.ToString() + @"\" + mediaDirectory + @"\" + mediaFileName).ToAbsoluteFilePath();

                //      var relativeFilePath2 = absoluteFilePath2.GetRelativePathFrom(absoluteDirectoryPath);
                var test = targetAbsoluteMediaPath.GetRelativePathFrom(targetAbsoluteDirectoryPath);
                string newMediaLink = test.ToString();
                if (newMediaLink.StartsWith(@".\"))
                {
                    newMediaLink = newMediaLink.Remove(0,2);
                }

                string replacementHTML = (File.ReadAllText(repo.Info.WorkingDirectory + sourcePattern))
                    .Replace(oldMediaLink, newMediaLink);
                // go back to linux links:
                replacementHTML = replacementHTML.Replace(@"\", @"/");
                ;
                File.WriteAllText(repo.Info.WorkingDirectory + sourcePattern, replacementHTML);
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
                File.ReadAllText(repo.Info.WorkingDirectory + sourcePattern), 
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
                        + @"\"
                        + Path.GetFileName(realSourcePath).ToLower();

                imageLocationList.Add(realSourcePath, targetMediaPath);

            }
            return imageLocationList;
        }

        /// <summary>
        /// Converts an absolute path to a file and an absolute path to a directory
        /// into a relative path from the directory to the file. 
        /// NOTE: Does not assume paths exist yet.
        /// </summary>
        /// <param name="toFileSpec">The absolute path to a target file. 
        /// would be "media\</param>
        /// <param name="fromFolder">the absolute path to a source directory.</param>
        /// <returns></returns>
        private string GetRelativePath(string toFileSpec, string fromFolder)
        {
            fromFolder = fromFolder.Replace(@"/", @"\");
            fromFolder = Path.Combine(repo.Info.WorkingDirectory, fromFolder);
            if (!toFileSpec.EndsWith(Path.DirectorySeparatorChar.ToString()))
            {
                toFileSpec += Path.DirectorySeparatorChar;
            }
            Uri pathUri = new Uri(Path.Combine(fromFolder + toFileSpec));

            // Folders must end in a slash
            if (!fromFolder.EndsWith(Path.DirectorySeparatorChar.ToString()))
            {
                fromFolder += Path.DirectorySeparatorChar;
            }
            Uri folderUri = new Uri(fromFolder);
            return Uri.UnescapeDataString(folderUri.MakeRelativeUri(pathUri).ToString().Replace('/', Path.DirectorySeparatorChar));
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
