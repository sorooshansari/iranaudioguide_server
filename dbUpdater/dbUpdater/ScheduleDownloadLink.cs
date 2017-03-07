﻿using dbUpdater.Services;
using Quartz;
using Quartz.Impl;
using System;
using System.Data;
using System.Linq;

namespace dbUpdater
{

    public class JobDownloadLinkDisable : IJob
    {

        public void Execute(IJobExecutionContext context)
        {
            //System.Diagnostics.Debug.WriteLine("job Disable:" + DateTime.Now.ToString());
            try
            {

                ServiceSqlServer.RunStoredProc("DownloadLinkDisable");



            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Exception Job Edite Download link.");
                //Elmah.ErrorSignal.FromCurrentContext().Raise(ex);

            }
        }



    }
    public class JobDownloadLinkRemove : IJob
    {

        public void Execute(IJobExecutionContext context)
        {
            //System.Diagnostics.Debug.WriteLine("job Remove:" + DateTime.Now.ToString());
            var serviceftp = new ServiceFtp();
            try
            {
                var dt = ServiceSqlServer.RunStoredProc("DownloadGetPathForDelete", true);
                var links = dt.AsEnumerable().Select(x => new PathVM
                {
                    Path = x["path"].ToString()
                }).ToList();
                foreach (var item in links)
                {
                    serviceftp.delete(item.Path);

                }
                ServiceSqlServer.RunStoredProc("DownloadLinkRemove");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(" Job remove Download link.");
                //Elmah.ErrorSignal.FromCurrentContext().Raise(ex);

            }
        }
        public interface ISchedule
        {
            void Run();
        }
        public class ScheduleDownloadLink : ISchedule
        {
            public void Run()
            {
                DateTimeOffset startTime = DateBuilder.FutureDate(10, IntervalUnit.Minute);

                IJobDetail job = JobBuilder.Create<JobDownloadLinkDisable>()
                                           .WithIdentity("jobDownloadLinkDisable")
                                           .Build();

                ITrigger trigger = TriggerBuilder.Create()
                                                 .WithIdentity("triggerDownloadLinkDisable")
                                                 .StartAt(startTime)
                                                 .WithSimpleSchedule(x => x.WithIntervalInMinutes(10).RepeatForever())
                                                 .Build();


                ISchedulerFactory sfDownloadLinkDisable = new StdSchedulerFactory();
                IScheduler sc = sfDownloadLinkDisable.GetScheduler();
                sc.ScheduleJob(job, trigger);
                sc.Start();



                DateTimeOffset startTimeRemove = DateBuilder.FutureDate(20, IntervalUnit.Minute);

                IJobDetail jobRemove = JobBuilder.Create<JobDownloadLinkRemove>()
                                           .WithIdentity("jobDownloadLinkRemove")
                                           .Build();

                ITrigger triggerRemove = TriggerBuilder.Create()
                                                 .WithIdentity("triggerDownloadLinkRemove")
                                                 .StartAt(startTimeRemove)
                                                 .WithSimpleSchedule(x => x.WithIntervalInMinutes(10).RepeatForever())
                                                 .Build();


                ISchedulerFactory sfDownloadLinkRemove = new StdSchedulerFactory();
                IScheduler scRemove = sfDownloadLinkRemove.GetScheduler();
                scRemove.ScheduleJob(jobRemove, triggerRemove);
                scRemove.Start();


            }
        }

    }
}