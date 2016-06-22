﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using IranAudioGuide_Server.Models;
using System.IO;
using System.Data.SqlClient;

namespace IranAudioGuide_Server.Controllers
{
    [Authorize]
    public class AdminController : Controller
    {
        private ApplicationDbContext db = new ApplicationDbContext();
        private const int pagingLen = 5;

        // GET: Admin
        [Authorize(Roles = "Admin")]
        public ActionResult Index()
        {
            ViewBag.View = Views.AdminIndex;

            return View(GetCurrentUserInfo());
        }
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public JsonResult Audios(string PlaceId)
        {
            if (PlaceId.Length > 0)
            {
                string imgUrl = PlaceImg(PlaceId);
                if (imgUrl != null)
                {
                    return Json(new AudioViewVM()
                    {
                        audios = GetAudios(PlaceId),
                        PlaceImage = imgUrl
                    });
                }
                return Json(new AudioViewVM()
                {
                    audios = GetAudios(PlaceId),
                    respond = new Respond(content: "Error. Couldn't find any image.", status: 1)
                });
            }
            return Json(new AudioViewVM()
            {
                respond = new Respond(content: "Fatal error. Invalid Place Id.", status: 2)
            });
        }
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public JsonResult AddPlace(NewPlace model)
        {
            if (!ModelState.IsValid)
            {
                return Json(new Respond("Check input fields", 1));
            }
            if (model.Image.ContentLength > 0 && IsImage(model.Image))
            {
                var place = new Place()
                {
                    Pla_Name = model.PlaceName,
                    Pla_Discription = model.PlaceDesc,
                    Pla_Address = model.PlaceAddress
                };
                if (model.PlaceCordinates != null)
                {
                    if (!model.PlaceCordinates.Contains(','))
                        return Json(new Respond("Enter X and Y cordinates and seprate them with \",\".", 2));
                    try
                    {
                        List<double> cordinates = (from c in model.PlaceCordinates.Split(',')
                                                   select Convert.ToDouble(c)).ToList();
                        place.Pla_cordinate_X = cordinates[0];
                        place.Pla_cordinate_Y = cordinates[1];
                    }
                    catch (Exception)
                    {
                        return Json(new Respond("Enter percise cordinates.", 2));
                    }
                }

                try
                {
                    using (var dbTran = db.Database.BeginTransaction())
                    {
                        place.Pla_city = db.Cities.Where(c => c.Cit_Id == model.PlaceCityId).FirstOrDefault();
                        db.Places.Add(place);
                        db.SaveChanges(); //Save place and generate Pla_Id
                        string id = Convert.ToString(place.Pla_Id);
                        string extention = Path.GetExtension(model.Image.FileName);
                        string path = string.Format("{0}{1}", id, extention);
                        model.Image.SaveAs(Server.MapPath(path));
                        place.Pla_ImgUrl = path;
                        db.SaveChanges();
                        dbTran.Commit();
                    }
                    return Json(new Respond(""));
                }
                catch (Exception ex)
                {

                    throw ex;
                }
            }
            return Json(new Respond("Only jpg, png, gif, and jpeg are allowed.", 3));
        }
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public JsonResult AddCity(NewCity model)
        {
            if (!ModelState.IsValid)
            {
                return Json(new OK(false));
            }
            var city = new city() { Cit_Name = model.CityName, Cit_Description = model.CityDesc };
            try
            {
                using (var dbTran = db.Database.BeginTransaction())
                {
                    db.Cities.Add(city);
                    db.SaveChanges();
                    dbTran.Commit();
                }
                return Json(new OK());
            }
            catch (Exception)
            {
                return Json(new OK(false));
            }
        }
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public JsonResult DelCity(int Id)
        {
            int result = db.Database.SqlQuery<int>("DeleteCity @Id", new SqlParameter("@Id", Id)).Single();
            return Json(new Respond("", result));
        }
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public JsonResult DelPlace(Guid Id)
        {
            int result = db.Database.SqlQuery<int>("DeletePlace @Id", new SqlParameter("@Id", Id)).Single();
            return Json(new Respond("", result));
        }
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public JsonResult GetPlaces(int PageNum)
        {
            var places = GetPlaces();
            int pagesLen = (places.Count() % 10 == 0) ? places.Count() / 10 : (places.Count() / 10) + 1;
            int remain = places.Count - (PageNum * pagingLen);
            return Json(new GetPlacesVM(
                (remain > pagingLen)
                ?
                    places.GetRange(PageNum * pagingLen, pagingLen)
                :
                    places.GetRange(PageNum * pagingLen, remain)
                , pagesLen));
        }
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public JsonResult GetCities(int PageNum)
        {
            var Cities = GetCities();
            int pagesLen = (Cities.Count() % pagingLen == 0) ? Cities.Count() / pagingLen : (Cities.Count() / pagingLen) + 1;
            int remain = Cities.Count - (PageNum * pagingLen);
            return Json(new GetCitiesVM(
                (remain > pagingLen)
                ?
                    Cities.GetRange(PageNum * pagingLen, pagingLen)
                :
                    Cities.GetRange(PageNum * pagingLen, remain)
                , pagesLen));
        }
        private List<PlaceVM> GetPlaces()
        {
            try
            {

                List<PlaceVM> Places = (from place in db.Places
                                        orderby place.Pla_Id descending
                                        select new PlaceVM()
                                        {
                                            PlaceId = place.Pla_Id,
                                            ImgUrl = place.Pla_ImgUrl.Remove(0, 1),
                                            PlaceDesc = place.Pla_Discription,
                                            PlaceName = place.Pla_Name,
                                            Audios = (from audio in db.Audios
                                                      where audio.Pla_Id == place
                                                      select new AudioVM()
                                                      {
                                                          Aud_Discription = audio.Aud_Discription,
                                                          Aud_Id = audio.Aud_Id,
                                                          Aud_Name = audio.Aud_Name,
                                                          Aud_Url = audio.Aud_Url.Remove(0, 1)
                                                      }).ToList(),
                                            CityName = (from c in db.Cities
                                                        where c == place.Pla_city
                                                        select c.Cit_Name).FirstOrDefault()
                                        }).ToList();
                int counter = 0;
                foreach (var item in Places)
                {
                    item.Index = ++counter;
                }
                return Places;
            }
            catch (Exception ex)
            {

                throw ex;
            }
        }

        private string PlaceImg(string placeId)
        {
            try
            {
                Place place = db.Places.Where(x => x.Pla_Id.ToString() == placeId).FirstOrDefault();
                if (place != default(Place))
                {
                    return place.Pla_ImgUrl;
                }
                return null;
            }
            catch (Exception ex)
            {

                throw ex;
            }
        }
        private UserInfo GetCurrentUserInfo()
        {
            try
            {
                string userName = User.Identity.Name;
                UserInfo Info = (from user in db.Users
                                 where user.UserName == userName
                                 select new UserInfo()
                                 {
                                     Email = user.Email,
                                     FullName = user.FullName,
                                     imgUrl = user.ImgUrl
                                 }).FirstOrDefault();
                return Info;
            }
            catch (Exception ex)
            {

                throw ex;
            }
        }
        private List<AudioVM> GetAudios(string PlaceId)
        {
            try
            {
                List<AudioVM> audios = (from a in db.Audios
                                        where a.Pla_Id == db.Places.Where(x => x.Pla_Id.ToString() == PlaceId).FirstOrDefault()
                                        select new AudioVM()
                                        {
                                            Aud_Discription = a.Aud_Discription,
                                            Aud_Name = a.Aud_Name,
                                            Aud_Url = a.Aud_Url,
                                            Aud_Id = a.Aud_Id
                                        }).ToList();
                int counter = 0;
                foreach (var item in audios)
                {
                    item.Index = ++counter;
                }
                return audios;
            }
            catch (Exception ex)
            {

                throw ex;
            }
        }
        private List<CityVM> GetCities()
        {
            try
            {
                List<CityVM> cities = (from c in db.Cities
                                       orderby c.Cit_Id descending
                                       select new CityVM()
                                       {
                                           CityDesc = c.Cit_Description,
                                           CityID = c.Cit_Id,
                                           CityName = c.Cit_Name
                                       }).ToList();
                int counter = 0;
                foreach (var item in cities)
                {
                    item.Index = ++counter;
                }
                return cities;
            }
            catch (Exception ex)
            {

                throw ex;
            }
        }
        private bool IsImage(HttpPostedFileBase file)
        {
            if (file.ContentType.Contains("image"))
            {
                return true;
            }

            string[] formats = new string[] { ".jpg", ".png", ".gif", ".jpeg" };

            // linq from Henrik Stenbæk
            return formats.Any(item => file.FileName.EndsWith(item, StringComparison.OrdinalIgnoreCase));
        }
        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}