﻿using IranAudioGuide_MainServer.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Results;

namespace IranAudioGuide_MainServer.Controllers
{
    public class AppManagerController : ApiController
    {
        dbTools dbTools = new dbTools();
        private AccountTools _acTools;
        public AccountTools acTools
        {
            get
            {
                return _acTools ?? new AccountTools();
            }
            private set
            {
                _acTools = value;
            }
        }
        //public SkippedUserVM skippedUser(string uuid)
        //{
        //    return dbTools.skipUser(uuid);
        //}
        [HttpPost]
        public async Task<AutorizedCitiesVM> GetAutorizedCities(string username, string uuid)
        {
            var res = new AutorizedCitiesVM();
            try
            {
                var user = await acTools.getUser(username, uuid);
                res.status =
                    (user == null) ? getUserStatus.notUser :
                    (user.uuid != uuid) ? getUserStatus.uuidMissMatch :
                    (!user.EmailConfirmed) ? getUserStatus.notConfirmed :
                    getUserStatus.confirmed;


                if (res.status == getUserStatus.confirmed)
                    res.cities = dbTools.GetAutorizedCities(user.Id);
            }
            catch (Exception ex)
            {
                res.status = getUserStatus.unknownError;
                res.errorMessage = ex.Message;
            }
            return res;
        }
        [HttpPost]
        // POST: api/AppManager/GetPackages/5
        public GetPackagesVM GetPackages(int cityId)
        {
            return dbTools.GetPackagesByCity(cityId);
        }
        [HttpPost]
        // POST: api/AppManager/GetUpdates/5
        public GetUpdateVM GetUpdates(int LastUpdateNumber, string uuid)
        {
            GetUpdateVM res;
            try
            {
                res = dbTools.GetUpdate(LastUpdateNumber, uuid);
            }
            catch (Exception ex)
            {
                res = new GetUpdateVM(ex.Message);
            }
            return res;
        }
        // POST: api/AppManager/GetAll
        [HttpPost]
        public GetAllVM GetAll(string uuid)
        {
            GetAllVM res;
            try
            {
                res = dbTools.GetAllEntries(uuid);
            }
            catch (Exception ex)
            {
                res = new GetAllVM(ex.Message);
            }
            return res;
        }
        [HttpPost]
        public async Task<CreateingUserResult> AutenticateGoogleUser(GoogleUserInfo user)
        {
            var res = await acTools.CreateGoogleUser(new ApplicationUser()
            {
                Email = user.email,
                GoogleId = user.google_id,
                UserName = user.email,
                Picture = user.picture,
                FullName = user.name,
                gender = (user.gender.ToLower() == "female") ? gender.Female : (user.gender.ToLower() == "male") ? gender.Male : gender.Unknown,
                EmailConfirmed = true,
                uuid = user.uuid
            });
            return res;
        }
        [HttpPost]
        public async Task<IHttpActionResult> ResgisterAppUser(AppUser user)
        {
            string baseUrl = Request.RequestUri.GetLeftPart(UriPartial.Authority);
            var res = await acTools.CreateAppUser(user.email, user.password, user.uuid, baseUrl);
            return Json(res);
        }
        [HttpPost]
        public async Task<AuthorizedUser> AuthorizeAppUser(AppUser user)
        {
            var res = await acTools.AutorizeAppUser(user.email, user.password, user.uuid);
            return res;
        }


        public IHttpActionResult GetCurrentUserInfo() {
            string userName = User.Identity.Name;
            var user = acTools.GetUserByName(userName);
            if (user == null)
                return null; 
            var userProfile = new UserProfile()
            {

                Email = user.UserName,
                FullName = user.FullName,
                imgUrl = user.ImgUrl,

            };
            userProfile.RolesName = acTools.GetUserRoles(user);
            return Ok(userProfile);
        }
        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                if (_acTools != null)
                {
                    _acTools.Dispose();
                    _acTools = null;
                }
            }

            base.Dispose(disposing);
        }

      
    }
}
