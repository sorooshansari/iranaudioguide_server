﻿using System;
using Quartz;
using Quartz.Impl;
using System.Linq;
using System.Data;

namespace dbUpdater.Services
{

    public class JobDownloadLinkDisable : IJob
    {

        public void Execute(IJobExecutionContext context)
        {
            //System.Diagnostics.Debug.WriteLine("job Disable:" + DateTime.Now.ToString());
            try
            {
                ServiceSqlServer.RunStoredProc("Download_LinkDisable");
            }
            catch 
            {
            }
        }
    }
    public class JobDownloadLinkRemove : IJob
    {

        public void Execute(IJobExecutionContext context)
        {
            //System.Diagnostics.Debug.WriteLine("job Remove:" + DateTime.Now.ToString());
            var serviceftp = new ServiceFtp();
            var isEmpty = true;
            try
            {
                var dt = ServiceSqlServer.RunStoredProc("Download_GetPathForDelete", true);
                var links = dt.AsEnumerable().Select(x => new PathVM
                {
                    Path = x["path"].ToString()
                }).ToList();
                foreach (var item in links)
                {
                    isEmpty = false;
                    serviceftp.delete(item.Path);

                }
                if (!isEmpty)
                    ServiceSqlServer.RunStoredProc("Download_LinkRemove");
            }
            catch 
            {

            }
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
            DateTimeOffset startTime = DateBuilder.FutureDate(1, IntervalUnit.Minute);

            IJobDetail job = JobBuilder.Create<JobDownloadLinkDisable>()
                                       .WithIdentity("jobDownloadLinkDisable")
                                       .Build();

            ITrigger trigger = TriggerBuilder.Create()
                                             .WithIdentity("triggerDownloadLinkDisable")
                                             .StartAt(startTime)
                                             .WithSimpleSchedule(x => x.WithIntervalInMinutes(3).RepeatForever())
                                             .Build();


            ISchedulerFactory sfDownloadLinkDisable = new StdSchedulerFactory();
            IScheduler sc = sfDownloadLinkDisable.GetScheduler();
            sc.ScheduleJob(job, trigger);
            sc.Start();



            DateTimeOffset startTimeRemove = DateBuilder.FutureDate(2, IntervalUnit.Minute);

            IJobDetail jobRemove = JobBuilder.Create<JobDownloadLinkRemove>()
                                       .WithIdentity("jobDownloadLinkRemove")
                                       .Build();

            ITrigger triggerRemove = TriggerBuilder.Create()
                                             .WithIdentity("triggerDownloadLinkRemove")
                                             .StartAt(startTimeRemove)
                                             .WithSimpleSchedule(x => x.WithIntervalInMinutes(5).RepeatForever())
                                             .Build();


            ISchedulerFactory sfDownloadLinkRemove = new StdSchedulerFactory();
            IScheduler scRemove = sfDownloadLinkRemove.GetScheduler();
            scRemove.ScheduleJob(jobRemove, triggerRemove);
            scRemove.Start();


        }
    }


}