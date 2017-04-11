﻿using LibGit2Sharp;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using NDepend.Path;
using System.Collections.Specialized;

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
        private bool @continue;
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
            this.@continue = commit;
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
            if (Regex.IsMatch(File.ReadAllText(Path.Combine(repo.Info.WorkingDirectory + sourcePattern)), "redirect_url:"))
            {
                // redirect file: we're not moving it.
                throw new Exception(String.Format("The file {0} is a redirect file; skipping.", sourcePattern));
                
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

            // Note: when I move this method up, I confuse the git implementation.
            // There remains something about files that git holds on to until you stage it; can't 
            // just keep making edits.
            RewriteOutboundLinks();
            WriteRedirectFile();
            CommitChanges();

        }

        private void RewriteOutboundLinks()
        {

            // for each outbound target file referenced, grab precisely the link from the file and replace it with the new link
           
            var outboundLinks = Regex.Matches(
                File.ReadAllText(repo.Info.WorkingDirectory + targetPattern),
                @"(?<=\]):{0,1}.+?.md"
            // above is the newline:
            // @"\[.+?\]\(.+?\)"
            );

            // TODO: what if the links are specified as ref anchors? Then the above regex will not catch them, and they won't be fixed.
            /*
             * 
             * Regex.Match(
                            File.ReadAllText(repo.Info.WorkingDirectory + file.Path),
                            @"(?<=\]:).+?" + originalFileName
                        );

            code for capturing ref anchors

            (?<=\]:).+?.md

            then, strip off the filename with Path.GetFilename and search for that.

            capture all links: (?<=\]):{0,1}.+?.md leaving online : or ( in front, so strip that out and continue normally.
             * */


            StringCollection rewrittenLinks = new StringCollection();

            foreach (Match currentOutboundLink in outboundLinks)
            {
                if (currentOutboundLink.Value.Contains("cli-install-nodejs.md"))
                {
                    ;
                }
                // old regex: "(?<=\]\().+?(?=\))" ==> current regex also catches reference anchors.
                string oldOutboundLink = (Regex.Match(currentOutboundLink.Value, @"(?<=[:\(]).*")).Value;
                if (oldOutboundLink.StartsWith(":") || oldOutboundLink.StartsWith("("))
                {
                    throw new Exception("well, THAT didn't work, now, did it?");
                }
                if (rewrittenLinks.Contains(oldOutboundLink))
                {
                    continue;
                }
                else
                {
                    rewrittenLinks.Add(oldOutboundLink);
                }
                // test code for links: is no op if not testing
                if (oldOutboundLink.Contains("app-service-logic-enterprise-integration-agreements.md"))
                {
                    ;
                }
                // GetRelativePath takes an absolute path to a file and an absolute path to a directory
                // and returns the relative path from the latter to the former.


                // issue:
                /*
                 * 
                 *    at System.IO.Path.CheckInvalidPathChars(String path, Boolean checkAdditional)
   at System.IO.Path.GetFileName(String path)
   at CSITools.GitMover.RewriteOutboundLinks() in C:\Users\rasquill\Documents\GitHub\gitwork\dotnet\move\GitMover\GitMover.cs:line 123
   at CSITools.GitMover.Move() in C:\Users\rasquill\Documents\GitHub\gitwork\dotnet\move\GitMover\GitMover.cs:line 101
   at links.MainClass.Main(String[] args) in C:\Users\rasquill\Documents\GitHub\gitwork\dotnet\move\move\Program.cs:line 78


                {[Azure Key Vault](../key-vault/key-vault-get-started.md "Learn about Key Vault")}  will cause this, which is valid.

                 * */
                // strip any filename out of the entire link.

                // first, capture the querystring, if any
                string queryString = string.Empty;
                if (oldOutboundLink.Contains("?"))
                {
                    queryString = oldOutboundLink.Substring(oldOutboundLink.IndexOf("?"));
                }
                

                // second, handle the removal of extraneous markdown goo
                oldOutboundLink = CleanURL(oldOutboundLink);

                // Ignore some links
                
                if (oldOutboundLink.StartsWith("http")) // link is internal to an H2; no file to rewrite; or external
                {

                    continue;
                }
                if (!oldOutboundLink.Contains(".md")) // it's a link, but not to anything we care about
                {
                    continue;
                }

                string targetFileName = "";
                try
                {
                   targetFileName = Path.GetFileName(oldOutboundLink);
                }
                catch (Exception ex)
                {
                    throw ex;
                }


                // handle the case where someone specified the "this" file name
                if (targetFileName.Equals(Path.GetFileName(sourcePattern)))
                {
                    targetFileName = Path.GetFileName(targetPattern);
                    targetFileName = CleanURL(targetFileName);
                    oldOutboundLink = oldOutboundLink.Replace(Path.GetFileName(sourcePattern), targetFileName);
                }
                
                var sourceAbsoluteDirectoryPath 
                    = (Path.GetDirectoryName(repo.Info.WorkingDirectory + targetPattern) + Path.DirectorySeparatorChar.ToString()).ToAbsoluteDirectoryPath();
                
                // TODO: need to search for all files to find the one that matches exactly, rather than assume the first one is correct.
                /*
                 * first, take the link and see if it exists in the file system. If it does, don't go looking any further and use that value.
                 * if it does not exist in the system, THEN go looking for PRECISELY the filename, and take a guess. There could be sixteen 
                 * "add-disk.md" files, and no way to decide if the original link was incorrect, so just take the first one and go.
                 * IN ADDITION: found file must NOT be a redirect file, which is an easy way of making a mistake.
                 */
                IndexEntry targetIndexEntryFromRepo;

                // if the file can be found on the file system and is NOT a redirect file, use that.

                // OK: a. Find out if there's more than one file.
                // b. if there's two files, choose the one that is not a redirect file.
                // c. if there's more, check the -c value and either throw or write to console. You can't guess.
                /*
                var repoFileHits = from t in repo.Index where t.Path.ToLower().Contains(targetFileName.ToLower()) select t;

                if (repoFileHits.Count() == 1)
                {
                    // this is assumed to be the file. 
                    // detect redirect and retarget using THAT file name to scuttle the redirect.
                }
                else if (repoFileHits.Count() == 2)
                {
                    // one of these is likely a redirect. if so, use the other one.
                }
                else if (repoFileHits.Count() > 2)
                {
                    // just take the first one if you can; but in all cases write out the situation and say you're going to guess
                    // throw an exception if -c is not specified, otherwise continue.
                }
                */

                // TODO: Here the problem is that if the targetfilename has been reset to the new name (in a recursivelink)
                // you're trying to find that file with the previous file name, which sets you on the wrong path. :-|
                // above, you should IF it's a recursive link, just reset oldOutboundLink to "this file" target pattern, I think.
            
                if (File.Exists(Path.Combine(sourceAbsoluteDirectoryPath.ToString(), oldOutboundLink)))
                {

                    if (Regex.IsMatch(File.ReadAllText(Path.Combine(sourceAbsoluteDirectoryPath.ToString(), oldOutboundLink)), "redirect_url:"))
                    {
                        // here extract and use the redirect value
                        string redirectlink = Regex.Match(currentOutboundLink.Value, @"(?<=redirect_url: /azure/).+?").Value;
                        targetIndexEntryFromRepo =
                            (from t in repo.Index where t.Path.ToLower().Contains(redirectlink.ToLower()) select t)
                            .FirstOrDefault();
                    }
                    else
                        targetIndexEntryFromRepo = 
                            (from t in repo.Index where t.Path.ToLower().Contains(targetFileName.ToLower()) select t)
                            .FirstOrDefault();
                }
                else // if the file IS either a redirect file OR the full path can't be found, search by file NAME and then retest for redirection.
                {
                    // Console.WriteLine("Cannot locate the outbound target \"{0}\" as a file; trying the filename in the repo.", oldOutboundLink);
                    var tempRepoHits =
                        (from t in repo.Index where t.Path.ToLower().Contains(@"\" + targetFileName.ToLower()) select t);
                    if (tempRepoHits != null && tempRepoHits.Count() == 1)
                    {
                        targetIndexEntryFromRepo = tempRepoHits.First();
                    }
                    // what if it's tWO? Gotta find the one that is NOT a redirect
                    else if (tempRepoHits != null && tempRepoHits.Count() == 2)
                    {
                        if (Regex.IsMatch(File.ReadAllText(repo.Info.WorkingDirectory + tempRepoHits.First().Path), "redirect_url:"))
                        {

                            // here extract and use the redirect value
                            string redirectlink = Regex.Match(File.ReadAllText(repo.Info.WorkingDirectory + tempRepoHits.First().Path), @"(?<=redirect_url: /azure/).*").Value;
                            if (redirectlink.EndsWith("\r"))
                            {
                                redirectlink = redirectlink.Remove(redirectlink.Length - 1);
                            }
                            redirectlink = redirectlink.Replace(@"/", @"\"); // on Windows, repo responds with windows separators.
                            targetIndexEntryFromRepo =
                                (from t in repo.Index where t.Path.ToLower().Contains(redirectlink.ToLower() + ".md") select t)
                                .FirstOrDefault();
                        }
                        else
                        {
                            //take the other one
                            targetIndexEntryFromRepo = tempRepoHits.ElementAt(1);
                        }
                    }
                    else // hey, just can't have confidence we know which one it might be.
                        targetIndexEntryFromRepo = null;
                }
            
                if (targetIndexEntryFromRepo == null)
                {
                    if (this.@continue)
                    {
                        Console.WriteLine(string.Format("Relinking file and cannot find linked file {0} or there are more than two possibilities.", targetFileName.ToLower()));
                        continue;
                    }
                    else
                        throw new Exception(string.Format("Cannot find file {0}.", targetFileName.ToLower()));
                }
                // Now we can construct the absolute path. Could have done this with strings, but.... 
                var targetAbsoluteOutboundLinkPath =
                    (Path.GetDirectoryName(repo.Info.WorkingDirectory + targetIndexEntryFromRepo.Path) + @"\" + targetFileName).ToAbsoluteFilePath();
                 
                //    var relativeFilePath2 = absoluteFilePath2.GetRelativePathFrom(absoluteDirectoryPath);
                var test = targetAbsoluteOutboundLinkPath.GetRelativePathFrom(sourceAbsoluteDirectoryPath);
                string newTargetLink = test.ToString().Replace(@"\", @"/");
                if (newTargetLink.StartsWith(@"./"))
                {
                    newTargetLink = newTargetLink.Remove(0, 2);
                }

                string replacementHTML = (File.ReadAllText(repo.Info.WorkingDirectory + targetPattern))
                    .Replace(oldOutboundLink, newTargetLink.ToLower());
                // go back to linux links:
                //replacementHTML = replacementHTML.Replace(@"\", @"/");
                File.WriteAllText(repo.Info.WorkingDirectory + targetPattern, replacementHTML);
                repo.Stage(repo.Info.WorkingDirectory + targetPattern);
            }
        }

        // removes everything from the end of a file link
        private string CleanURL(string oldOutboundLink)
        {
            if (oldOutboundLink.IndexOf(' ') != -1)
            {
                oldOutboundLink = oldOutboundLink.Remove(oldOutboundLink.IndexOf(' '));
            }
            if (oldOutboundLink.IndexOf('?') != -1)
            {
                oldOutboundLink = oldOutboundLink.Remove(oldOutboundLink.IndexOf('?'));
            }
            if (oldOutboundLink.IndexOf('#') != -1)
            {
                oldOutboundLink = oldOutboundLink.Remove(oldOutboundLink.IndexOf('#'));
            }
            if (oldOutboundLink.StartsWith(@"./"))
            {
                oldOutboundLink = oldOutboundLink.Remove(0, 2);
            }
            return oldOutboundLink;
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
                string tempRedirectString = targetPattern.Replace(@"articles\", "").Replace(@"\", @"/").Replace(".md", "");
                StreamWriter redirectFile = File.CreateText(repo.Info.WorkingDirectory + sourcePattern);
                redirectFile.WriteLine("---");
                redirectFile.WriteLine("redirect_url: /azure/" + tempRedirectString);
                redirectFile.WriteLine("redirect_document_id: true");
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
                string newIncludeRelativeLink = targetIncludeAbsoluteFilePath.GetRelativePathFrom(fromAbsoluteDirectoryPath).ToString().Replace(@"\", @"/");
                if (newIncludeRelativeLink.StartsWith(@".\"))
                {
                    newIncludeRelativeLink = newIncludeRelativeLink.Remove(0, 2);
                }

                string replacementHTML = (File.ReadAllText(repo.Info.WorkingDirectory + sourcePattern))
                    .Replace(oldIncludeRelativeLink, newIncludeRelativeLink);
                // go back to linux links:
                // replacementHTML = replacementHTML.Replace(@"\", @"/");
                
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
                            select i;

            Regex justFilePattern = new Regex(originalFileName);

            foreach (IndexEntry file in repoFiles)
            {
                // test for debugging
                if (file.Path.Contains("apis-list.md"))
                {
                    ;
                }
                //  if it has a match: focus!
                if (justFilePattern.IsMatch(File.ReadAllText(repo.Info.WorkingDirectory + file.Path)))
                {
                    // get all matches in links
                    var oldInboundLinks = Regex.Match(
                        File.ReadAllText(repo.Info.WorkingDirectory + file.Path),
                        @"(?<=\]\()\S*" + originalFileName
                    );

                    if (!oldInboundLinks.Success)
                    {
                        // this means likely we have reference links. booo:
                        oldInboundLinks = Regex.Match(
                            File.ReadAllText(repo.Info.WorkingDirectory + file.Path),
                            @"(?<=\]:).+?" + originalFileName
                        );
                        if (!oldInboundLinks.Success)
                        {
                            continue;
                        }
                    }
                    var sourceAbsoluteDirectoryPath = (
                        Path.GetDirectoryName(repo.Info.WorkingDirectory + file.Path) + Path.DirectorySeparatorChar.ToString()).ToAbsoluteDirectoryPath();
                    var targetAbsoluteFilePath =
                        (repo.Info.WorkingDirectory + targetPattern).ToAbsoluteFilePath();

                    //      var relativeFilePath2 = absoluteFilePath2.GetRelativePathFrom(absoluteDirectoryPath);
                    // Make relative link to new location
                    string newInboundLink = targetAbsoluteFilePath.GetRelativePathFrom(sourceAbsoluteDirectoryPath).ToString();
                    if (newInboundLink.StartsWith(@".\"))
                    {
                        newInboundLink = newInboundLink.Remove(0, 2);
                    }
                    newInboundLink = newInboundLink.Replace(@"\", @"/");


                    // for each link match, replace that with the new, relative link.
                    // BUG: if the file is the same name but in a different location, we need to do this only once for all things.
                    string replaceText = "";
                    try
                    {
                        replaceText = File.ReadAllText(repo.Info.WorkingDirectory + file.Path).Replace(oldInboundLinks.Value, newInboundLink);
                    }
                    catch ( Exception ex)
                    {
                        throw ex;
                    }
                        File.WriteAllText(repo.Info.WorkingDirectory + file.Path, replaceText);
                        repo.Stage(file.Path);
                }
             }
        }


        private void MoveFile()
        {
            // Why move does not create the directory, I have no idea. But it killed about two days figuring it out 
            // given that the error message is crazy bad.

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
                string newPath = mediaFileEntry.Value.ToString().ToLower(); 

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

            /*
             * TODO: if there's an issue below with media files not being found, the links to them will not be rewritten
             */

            string mediaDirectory =
                @"media\"
                + Path.GetFileNameWithoutExtension(targetPattern)
                + @"\";

            // for each media file referenced, grab precisely the link from the file and replace it with the new link
            // in the form: media\<new markdown file name>\<same media file name>

            // logging elaboration: 
            /* 
             * Case: another file shares media files. 
             * Fix: search for the original media file FIRST, and if you don't find it, then search for the new media file. 
             * If you can find THAT one, use THAT link, not the original link.
             * 
             */



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
                string newMediaLink = test.ToString().Replace(@"\", @"/");
                if (newMediaLink.StartsWith(@".\"))
                {
                    newMediaLink = newMediaLink.Remove(0,2);
                }

                string replacementHTML = (File.ReadAllText(repo.Info.WorkingDirectory + sourcePattern))
                    .Replace(oldMediaLink, newMediaLink);
                // go back to linux links:
                // replacementHTML = replacementHTML.Replace(@"\", @"/");
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
                                      where m.Path.ToLower().Contains(sourceMediaPath.ToLower())
                                      select m;

                if (mediaIndexEntry.Count() == 0)
                {
                    if (this.@continue)
                    {
                        Console.WriteLine(string.Format("Can't find the media {0}; was it moved already? Check for the file in master.", sourceMediaPath));
                        continue;
                    }
                    else
                        throw new Exception(string.Format("Can't find the media {0}; was it moved already? Check for the file in master.", sourceMediaPath));
                }
    
                if (mediaIndexEntry.Count() != 1)
                {
                    if (this.@continue)
                    {
                        Console.WriteLine(string.Format("Media file {0} has more than one version. How's that possible?", sourceMediaPath));
                        continue;
                    }
                    else
                        throw new Exception(string.Format("Media file {0} has more than one version. How's that possible?", sourceMediaPath));
                }

                string realSourcePath = mediaIndexEntry.First().Path;
                string targetMediaPath = Path.GetDirectoryName(targetPattern)
                        + @"\media\"
                        + Path.GetFileNameWithoutExtension(targetPattern).ToLower()
                        + @"\"
                        + Path.GetFileName(realSourcePath).ToLower();
                if (!imageLocationList.ContainsKey(realSourcePath))
                {
                    imageLocationList.Add(realSourcePath, targetMediaPath);
                }
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
      
        public void Unwind()
        {
            // Force reset the branch to what it was.
            repo.Reset(ResetMode.Hard);
            this.Dispose();
        }

        public void Dispose()
        {
            repo.Dispose();
        }
    }
}
