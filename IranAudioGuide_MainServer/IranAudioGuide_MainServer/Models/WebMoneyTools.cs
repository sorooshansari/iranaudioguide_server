﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Web;

namespace IranAudioGuide_MainServer.Models
{
    public static class WebmoneyPurse
    {
        public static readonly string Id = "Z945718891756";
    }
    public class WebmoneyServices
    {
        public WMUpdateRes ProccessResult()
        {
            int paymentId;
            ApplicationDbContext db;
            WMPayment payment;
            string userEmail, packName;
            float primtivePrice;
            EmailService es = new EmailService();
            try
            {
                paymentId = Convert.ToInt32(ReturnModel.LMI_PAYMENT_NO);
                db = new ApplicationDbContext();
                payment = db.WMPayment.Include("User").Include("Package").Where(x => x.PaymentId == paymentId).FirstOrDefault();
                if (payment == default(WMPayment))
                    return new WMUpdateRes("Sorry, Your payment was unsuccessful!",
                        "Your payment process does not completed. <br />",
                        paymentId,
                        "",
                        false);
                userEmail = payment.User.Email;
                primtivePrice = payment.Package.Pac_Price_Dollar;
                packName = payment.Package.Pac_Name;
            }
            catch (Exception)
            {
                return new WMUpdateRes("Sorry, Your payment was unsuccessful!",
                    "Your payment process does not completed. <br />",
                    -1,
                    "",
                    false);
            }
            try
            {
                bool isPriceCorrect = primtivePrice == float.Parse(ReturnModel.LMI_PAYMENT_AMOUNT);
                bool isIntegrate = ControlSignature() && isPriceCorrect;
                if (!isIntegrate)
                {
                    es.SendAsync(new Microsoft.AspNet.Identity.IdentityMessage()
                    {
                        Subject = "failed",
                        Body = "khodahafez",
                        Destination = userEmail
                    });
                }
                payment.DataIntegrity = isIntegrate;

                if (ReturnModel.LMI_CAPITALLER_WMID != null)
                    payment.WMP_CAPITALLER_WMID = ReturnModel.LMI_CAPITALLER_WMID;

                if (ReturnModel.LMI_HOLD != null)
                    payment.WMP_HOLD = ReturnModel.LMI_HOLD;

                if (ReturnModel.LMI_CAPITALLER_WMID != null)
                    payment.WMP_CAPITALLER_WMID = ReturnModel.LMI_CAPITALLER_WMID;

                if (ReturnModel.LMI_MODE != null)
                    payment.WMP_MODE = ReturnModel.LMI_MODE;

                if (ReturnModel.LMI_PAYEE_PURSE != null)
                    payment.WMP_PAYEE_PURSE = ReturnModel.LMI_PAYEE_PURSE;

                if (ReturnModel.LMI_PAYER_COUNTRYID != null)
                    payment.WMP_PAYER_COUNTRYID = ReturnModel.LMI_PAYER_COUNTRYID;

                if (ReturnModel.LMI_PAYER_IP != null)
                    payment.WMP_PAYER_IP = ReturnModel.LMI_PAYER_IP;

                if (ReturnModel.LMI_PAYER_PCOUNTRYID != null)
                    payment.WMP_PAYER_PCOUNTRYID = ReturnModel.LMI_PAYER_PCOUNTRYID;

                if (ReturnModel.LMI_PAYER_PURSE != null)
                    payment.WMP_PAYER_PURSE = ReturnModel.LMI_PAYER_PURSE;

                if (ReturnModel.LMI_PAYER_WM != null)
                    payment.WMP_PAYER_WM = ReturnModel.LMI_PAYER_WM;

                if (ReturnModel.LMI_PAYMENT_AMOUNT != null)
                    payment.WMP_PAYMENT_AMOUNT = ReturnModel.LMI_PAYMENT_AMOUNT;

                if (ReturnModel.LMI_PAYMENT_CREDITDAYS != null)
                    payment.WMP_PAYMENT_CREDITDAYS = ReturnModel.LMI_PAYMENT_CREDITDAYS;

                if (ReturnModel.LMI_PAYMENT_NO != null)
                    payment.WMP_PAYMENT_NO = ReturnModel.LMI_PAYMENT_NO;

                if (ReturnModel.LMI_PAYMER_EMAIL != null)
                    payment.WMP_PAYMER_EMAIL = ReturnModel.LMI_PAYMER_EMAIL;

                if (ReturnModel.LMI_PAYMER_NUMBER != null)
                    payment.WMP_PAYMER_NUMBER = ReturnModel.LMI_PAYMER_NUMBER;

                if (ReturnModel.LMI_SDP_TYPE != null)
                    payment.WMP_SDP_TYPE = ReturnModel.LMI_SDP_TYPE;

                if (ReturnModel.LMI_SYS_INVS_NO != null)
                    payment.WMP_SYS_INVS_NO_Result = ReturnModel.LMI_SYS_INVS_NO;

                if (ReturnModel.LMI_SYS_TRANS_DATE != null)
                    payment.WMP_SYS_TRANS_DATE_Result = DateTime.ParseExact(ReturnModel.LMI_SYS_TRANS_DATE, "yyyyMMdd HH:mm:ss", System.Globalization.CultureInfo.InvariantCulture);

                if (ReturnModel.LMI_SYS_TRANS_NO != null)
                    payment.WMP_SYS_TRANS_NO_Result = ReturnModel.LMI_SYS_TRANS_NO;

                db.SaveChanges();
                db.Dispose();

                if (!isIntegrate)
                {
                    return new WMUpdateRes("Sorry, Your payment was unsuccessful!",
                        "Your payment process does not completed. <br />",
                        paymentId,
                        packName,
                        false);
                }
                return new WMUpdateRes("Sorry, Your payment was unsuccessful!",
                    "Your payment process does not completed. <br />",
                    paymentId,
                    packName,
                    false);
            }
            catch (Exception)
            {
                payment.DataIntegrity = false;
                db.SaveChanges();
                db.Dispose();
                es.SendAsync(new Microsoft.AspNet.Identity.IdentityMessage()
                {
                    Subject = "failed",
                    Body = "khodahafez",
                    Destination = userEmail
                });
                return new WMUpdateRes("Sorry, Your payment was unsuccessful!",
                        "Your payment process does not completed. <br />",
                        paymentId,
                        packName,
                        false);
            }
        }
        public WMUpdateRes Failed()
        {
            try
            {
                int paymentId = Convert.ToInt32(ReturnModel.LMI_PAYMENT_NO);
                using (var db = new ApplicationDbContext())
                {
                    var packName = db.WMPayment.Include("Package").Where(x => x.PaymentId == paymentId).FirstOrDefault().Package.Pac_Name;
                    return new WMUpdateRes("Sorry, Your payment was unsuccessful!",
                        "Your payment process does not completed. <br />",
                        paymentId,
                        packName,
                        false);
                }
            }
            catch (Exception)
            {
                return new WMUpdateRes("Sorry, Your payment was unsuccessful!",
                    "Your payment process does not completed. <br />",
                    0,
                    "",
                    false);
            }
        }
        public WMUpdateRes Succeeded()
        {
            if (ReturnModel.LMI_PAYMENT_NO != null)
            {
                try
                {
                    int paymentId = Convert.ToInt32(ReturnModel.LMI_PAYMENT_NO);
                    using (var db = new ApplicationDbContext())
                    {
                        var payment = db.WMPayment.Include("User").Include("Package").Where(x => x.PaymentId == paymentId).FirstOrDefault();
                        if (payment == default(WMPayment))
                            return new WMUpdateRes("Sorry, Your payment was unsuccessful!",
                                "You have access to the package below. Thank you for your purchase! <br />",
                                paymentId,
                                payment.Package.Pac_Name,
                                false);
                        payment.WMP_SYS_INVS_NO = ReturnModel.LMI_SYS_INVS_NO;
                        payment.WMP_SYS_TRANS_NO = ReturnModel.LMI_SYS_TRANS_NO;
                        payment.WMP_SYS_TRANS_DATE = DateTime.ParseExact(ReturnModel.LMI_SYS_TRANS_DATE, "yyyyMMdd HH:mm:ss", System.Globalization.CultureInfo.InvariantCulture);
                        payment.PaymentFinished = true;
                        db.SaveChanges();
                        var es = new EmailService();
                        es.SendAsync(new Microsoft.AspNet.Identity.IdentityMessage()
                        {
                            Subject = "success",
                            Body = "salam",
                            Destination = payment.User.Email
                        });
                        return new WMUpdateRes("Payment completed successfully.",
                            "You have access to the package below. Thank you for your purchase! <br />",
                            paymentId,
                            payment.Package.Pac_Name,
                            true);
                    }

                }
                catch (Exception ex)
                {

                    return new WMUpdateRes("Sorry, Your payment was unsuccessful!",
                        "If the payment is deducted from your bank account, The amount will be automatically returned. If not, please contact us.",
                        0,
                        "",
                        false);
                }
            }
            return new WMUpdateRes("Sorry, Your payment was unsuccessful!",
                "If the payment is deducted from your bank account, The amount will be automatically returned. If not, please contact us.",
                0,
                "",
                false);
        }
        public WMPaymentResult CreatePayment(string UserName, Guid packageId)
        {
            try
            {
                using (var db = new ApplicationDbContext())
                {
                    var user = db.Users.Where(x => x.UserName == UserName).First();
                    var package = db.Packages.Where(x => x.Pac_Id == packageId).First();
                    WMPayment payment = new WMPayment()
                    {
                        User = user,
                        Package = package
                    };
                    db.WMPayment.Add(payment);
                    db.SaveChanges();
                    return new WMPaymentResult()
                    {
                        PackageAmount = package.Pac_Price_Dollar,
                        PackageName = package.Pac_Name,
                        PaymentId = payment.PaymentId
                    };
                }
            }
            catch (Exception ex)
            {
                return new WMPaymentResult() { PaymentId = 0 };
            }
        }
        public bool ControlSignature()
        {
            var sb = new StringBuilder();
            sb.Append(ReturnModel.LMI_PAYEE_PURSE + ";");
            sb.Append(ReturnModel.LMI_PAYMENT_AMOUNT + ";");
            if (ReturnModel.LMI_HOLD != null && ReturnModel.LMI_HOLD != "")
                sb.Append(ReturnModel.LMI_HOLD + ";");
            sb.Append(ReturnModel.LMI_PAYMENT_NO + ";");
            sb.Append(ReturnModel.LMI_MODE + ";");
            sb.Append(ReturnModel.LMI_SYS_INVS_NO + ";");
            sb.Append(ReturnModel.LMI_SYS_TRANS_NO + ";");
            sb.Append(ReturnModel.LMI_SYS_TRANS_DATE + ";");
            sb.Append(ReturnModel.LMI_SECRET_KEY + ";");
            sb.Append(ReturnModel.LMI_PAYER_PURSE + ";");
            sb.Append(ReturnModel.LMI_PAYER_WM);

            byte[] bytes = System.Text.Encoding.UTF8.GetBytes(sb.ToString());

            var sha256 = SHA256.Create();
            byte[] hashBytes = sha256.ComputeHash(bytes);

            string res = HexStringFromBytes(hashBytes);

            return res.ToLower() == ReturnModel.LMI_HASH2.ToLower();
        }
        private static string HexStringFromBytes(byte[] bytes)
        {
            var sb = new System.Text.StringBuilder();
            foreach (byte b in bytes)
            {
                var hex = b.ToString("x2");
                sb.Append(hex);
            }
            return sb.ToString();
        }
        public WMReturnModel ReturnModel { get; set; }
    }
    public class WMPaymentResult
    {
        public int PaymentId { get; set; }
        public string PackageName { get; set; }
        public float PackageAmount { get; set; }
    }
    public class WMReturnModel
    {
        public string LMI_PAYEE_PURSE { get; set; }
        public string LMI_PAYMENT_AMOUNT { get; set; }
        public string LMI_HOLD { get; set; }
        public string LMI_PAYMENT_NO { get; set; }
        public string LMI_MODE { get; set; }
        public string LMI_SYS_INVS_NO { get; set; }
        public string LMI_SYS_TRANS_NO { get; set; }
        public string LMI_SYS_TRANS_DATE { get; set; }
        public string LMI_SECRET_KEY { get; set; }
        public string LMI_PAYER_PURSE { get; set; }
        public string LMI_PAYER_WM { get; set; }
        public string LMI_HASH { get; set; }
        public string LMI_HASH2 { get; set; }


        public string LMI_CAPITALLER_WMID { get; set; }
        public string LMI_PAYMER_NUMBER { get; set; }
        public string LMI_PAYMER_EMAIL { get; set; }
        public string LMI_EURONOTE_NUMBER { get; set; }
        public string LMI_EURONOTE_EMAIL { get; set; }
        public string LMI_WMCHECK_NUMBER { get; set; }
        public string LMI_TELEPAT_PHONENUMBER { get; set; }
        public string LMI_TELEPAT_ORDERID { get; set; }
        public string LMI_PAYMENT_CREDITDAYS { get; set; }

        public string LMI_SDP_TYPE { get; set; }
        public string LMI_PAYER_COUNTRYID { get; set; }
        public string LMI_PAYER_PCOUNTRYID { get; set; }
        public string LMI_PAYER_IP { get; set; }
    }
    public class WMUpdateRes
    {
        public WMUpdateRes(string message, string description, int paymentId, string packName, bool succeeded)
        {
            Message = message;
            ErrDesc = description;
            refId = paymentId.ToString();
            Image = succeeded ? "<i class=\"fa fa-check\" style=\"color: lightgreen; font-size:35px; vertical-align:sub; \"></i>" :
                "<i class=\"fa fa-exclamation-triangle\" style=\"color: Yellow; font-size:35px; vertical-align:sub; \"></i>";
            PackName = packName;
        }
        public string Message { get; set; }
        public string Image { get; set; }
        public string refId { get; set; }
        public string ErrDesc { get; set; }
        public string PackName { get; set; }

    }
}