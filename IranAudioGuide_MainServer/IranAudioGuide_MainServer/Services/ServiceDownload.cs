﻿using IranAudioGuide_MainServer.Models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;


namespace IranAudioGuide_MainServer.Services
{
    public class ServiceDownload
    {
        private dbManager _dbManager;
        public dbManager dbManager
        {
            get
            {
                return _dbManager ?? new dbManager();
            }
            private set
            {
                _dbManager = value;
            }
        }

        internal List<GetAudioUrlVM> testurl()
        {
            using (var db = new ApplicationDbContext())
            {
                var list = db.Audios
                    .Select(x => new GetAudioUrlVM()
                    {
                        email = "12",
                        uuid = "12",
                        trackId = x.Aud_Id,
                        isAudio = true
                    }).ToList();
                var list2 = db.Storys
                    .Select(x => new GetAudioUrlVM()
                    {
                        email = "12",
                        uuid = "12",
                        trackId = x.Sto_Id,
                        isAudio = false
                    }).ToList();
                list.AddRange(list2);
                return list;
            }

        }
        public void test()
        {  
            //var list = testurl();

            //string[] urllist = new string[list.Count + 2];
            //var i = 0;
            //foreach (var model2 in list)
            //{
            //    var s = GetAudioUrl(model2);
            //    urllist[i++] = s;
            //}
        }

        public string GetUrlOldVersion(string fileName, bool isAudio)
        {

            string pathSource, pathDestination;
            string url = "";
            if (isAudio)
            {

                pathSource = GlobalPath.FullPathAudios;
                pathDestination = GlobalPath.DownloadPathAudios;
            }
            else
            {
                pathSource = GlobalPath.FullPathStory;
                pathDestination = GlobalPath.DownloadPathStory;
            }

            DownloadLink link = new DownloadLink();
            using (var db = new ApplicationDbContext())
            {
                using (var dbTran = db.Database.BeginTransaction())
                {
                    var Path = db.DownloadLinks.FirstOrDefault(x => x.FileName == fileName & x.IsDisable == false & x.IsAudio == isAudio);
                    if (Path == null)
                    {

                        link.FileName = fileName;
                        link.TimeToVisit = DateTime.Now;
                        link.IsAudio = isAudio;
                        db.DownloadLinks.Add(link);

                    }
                    else
                    {
                        Path.TimeToVisit = DateTime.Now;
                        url = Path.Path;
                    }
                    try
                    {
                        db.SaveChanges();
                        if (Path == null)
                        {
                            link.Path = string.Format("{0}/{1}", pathDestination, link.Dow_Id + System.IO.Path.GetExtension(fileName));
                            url = link.Path;
                            db.SaveChanges();
                        }

                        dbTran.Commit();
                        if (Path == null)
                        {
                            var ftp = new ServiceFtp();
                            pathSource = pathSource + "/" + fileName;
                            pathDestination = pathDestination + "/" + link.Dow_Id + System.IO.Path.GetExtension(fileName);
                            ftp.Copy(pathSource, pathDestination);
                        }
                        return GlobalPath.host + "/" + url;
                    }
                    catch (Exception ex)
                    {
                        dbTran.Rollback();
                        throw new ArgumentException("Dont Save Download link in DataBase Or Dont Copy File in Server", "original");
                    }
                }
            }
        }

        public static string GetUrl(GetAudioUrlVM model, bool isAdmin = false)
        {
            string pathSource, pathDestination;
            if (model.isAudio)
            {

                pathSource = GlobalPath.FullPathAudios;
                pathDestination = GlobalPath.DownloadPathAudios;
            }
            else
            {
                pathSource = GlobalPath.FullPathStory;
                pathDestination = GlobalPath.DownloadPathStory;
            }
            using (SqlConnection sqlConnection = new SqlConnection(GlobalPath.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand("GetURL", sqlConnection); cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.Add(new SqlParameter("@IsAudio", model.isAudio));
                cmd.Parameters.Add(new SqlParameter("@FileId", model.trackId));
                cmd.Parameters.Add(new SqlParameter("@UserName", model.email));
                cmd.Parameters.Add(new SqlParameter("@UserUUID", model.uuid));
                cmd.Parameters.Add(new SqlParameter("@Path", pathDestination));
                cmd.Parameters.Add(new SqlParameter("@IsAdmin",isAdmin ));

                sqlConnection.Open();
                var reader = cmd.ExecuteReader();
                var dt1 = new DataTable();
                dt1.Load(reader);
                var links = dt1.AsEnumerable().Select(x => new
                {
                    PathFile = x["PathFile"].ToString(),
                    FileName = x["FileName"].ToString(),
                    IsUpdate = x["IsUpdate"].ToString(),
                    IsAccess = x["isAccess"].ToString()
                }).FirstOrDefault();

                if (links.IsAccess == "0")
                    return null;
                if (links.IsUpdate == "True")
                {
                    var ftp = new ServiceFtp();
                    pathSource = pathSource + "/" + links.FileName;
                    pathDestination = links.PathFile;
                    ftp.Copy(pathSource, pathDestination);
                }
                return GlobalPath.host + "/" + links.PathFile;
            }
        }
    }
}