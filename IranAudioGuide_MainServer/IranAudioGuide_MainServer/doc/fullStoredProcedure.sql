/****** Object:  StoredProcedure [dbo].[CreateComment]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CreateComment] 
      @Message NVARCHAR(MAX),
      @uuid NVARCHAR(MAX),
      @Subject NVARCHAR(MAX),
      @email NVARCHAR(MAX)
AS
BEGIN
      INSERT INTO [dbo].[Comments] (Subject, Message, CreateTime, Email, IsRead, uuid)
VALUES        (@Subject ,@Message, getdate(), @email, 'False' ,@uuid)
      
END

GO
/****** Object:  StoredProcedure [dbo].[DeleteCity]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DeleteCity]
    @Id int
AS
BEGIN
    DECLARE @ErrorNumber INT
    BEGIN TRY
          DELETE FROM dbo.cities
          WHERE Cit_Id = @Id

          SELECT 0
    END TRY
    BEGIN CATCH
          SELECT @ErrorNumber = ERROR_NUMBER()
          IF @ErrorNumber = 547
                SELECT 1
          ELSE
                SELECT 2
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[DeletePlace]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DeletePlace]
    @Id uniqueidentifier
AS
BEGIN
    DECLARE @ErrorNumber INT
    BEGIN TRY
          DELETE FROM dbo.Places
          WHERE Pla_Id = @Id

          SELECT 0
    END TRY
    BEGIN CATCH
          SELECT @ErrorNumber = ERROR_NUMBER()
          IF @ErrorNumber = 547
                SELECT 1
          ELSE
                SELECT 2
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Download_GetPathForDelete]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Download_GetPathForDelete]
            AS          
            BEGIN
                  SELECT DownloadLinks.Path           
                  FROM DownloadLinks            WHERE (IsDisable = 1) AND (TimeToVisit <= DATEADD (mi , 20 , TimeToVisit))
            END
GO
/****** Object:  StoredProcedure [dbo].[Download_Link_GetURL]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Download_Link_GetURL] 
                @IsAudio bit,
                @IsAdmin bit,
                @FileId uniqueidentifier,
                @UserName nvarchar(max),
                @Path nvarchar(max), 
                @UserUUID nvarchar(max)

            AS
            BEGIN
            
                DECLARE @isAccess bit
                DECLARE @FileName nvarchar(max)
                DECLARE @PackagesId uniqueidentifier 
                DECLARE @IsUpdate bit
                DECLARE @langId int
                DECLARE @IdDownload uniqueidentifier 
                DECLARE @IdTrack uniqueidentifier 

                  

                IF @IsAudio = 1
                        BEGIN
                              
                                SELECT @IdTrack = Aud_Id,  @FileName = Audios.Aud_Url, @langId = Audios.langId,  @PackagesId = Packages.Pac_Id , @isAccess = Places.Pla_isPrimary
                                    FROM   Audios 
                                          INNER JOIN Places ON Audios.Place_Pla_Id = Places.Pla_Id 
                                          INNER JOIN  cities ON Places.Pla_city_Cit_Id = cities.Cit_Id 
                                          INNER JOIN  Packagecities ON cities.Cit_Id = Packagecities.city_Cit_Id 
                                          INNER JOIN  Packages ON Packagecities.Package_Pac_Id = Packages.Pac_Id
                                                WHERE  (Audios.Aud_Id = @FileId) 
                        END
                ELSE 
                        BEGIN
                              SELECT @IdTrack = Sto_Id,  @FileName = Stories.Sto_Url,@langId = Stories.langId, @PackagesId = Packages.Pac_Id , @isAccess = Places.Pla_isPrimary
                                    FROM   Stories 
                                          INNER JOIN Places ON Stories.Place_Pla_Id = Places.Pla_Id 
                                          INNER JOIN  cities ON Places.Pla_city_Cit_Id = cities.Cit_Id 
                                          INNER JOIN  Packagecities ON cities.Cit_Id = Packagecities.city_Cit_Id 
                                          INNER JOIN  Packages ON Packagecities.Package_Pac_Id = Packages.Pac_Id
                                                WHERE  (Stories.Sto_Id = @FileId) 
                        END
                                    
                  
                IF (@IsAdmin= 0  and  @isAccess = 0)
                      BEGIN
                              
                            SELECT @isAccess = COUNT(DISTINCT Procurements.Id)  FROM Procurements INNER JOIN Packages 
                                  ON Procurements.Pac_Id = Packages.Pac_Id
                                  INNER JOIN AspNetUsers ON AspNetUsers.Id = Procurements.Id
                                  where (AspNetUsers.UserName = @UserName and AspNetUsers.uuid = @UserUUID and Packages.Pac_Id = @PackagesId) 
                      END
                        
                  IF( @IsAdmin= 1  or  @isAccess != 0)
                      Begin
                            EXEC    [dbo].[Download_LinkCreate]
                                        @FileName = @FileName,
                                        @IsAudio = @IsAudio,
                                        @Path = @Path OUTPUT,
                                        @IsUpdate = @IsUpdate OUTPUT,
                                                @IdDownload = @IdDownload OUTPUT

                            SELECT  @Path as PathFile , @FileName as FileName , @IsUpdate as IsUpdate , 1 as isAccess, @langId as  langId,@IdDownload as IdDownload
                    
                          INSERT INTO TrafficDownloadLogs
                               (Tra_Uuid, Tra_DateTime,Tra_IsAudio ,Tra_IdTrack)
                                     VALUES (@UserUUID, GETDATE(),@IsAudio,@IdTrack)
                          
                            END
                ELSE 
                        BEGIN
                            SELECT  null as PathFile , null as FileName , null as IsUpdate , 0 as isAccess , @langId as  langId,@IdDownload as IdDownload
                        END
                  END
GO
/****** Object:  StoredProcedure [dbo].[Download_LinkCreate]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Download_LinkCreate]
                  @FileName nvarchar(max),
                  @IsAudio bit,
                  @Path nvarchar(max) output, 
                  @IsUpdate bit output,
                  @IdDownload uniqueidentifier OUTPUT

            AS
            BEGIN
                  DECLARE @downloadTable TABLE
                  (
                        [Dow_Id] [uniqueidentifier] NULL  DEFAULT (newsequentialid())
                  )
                  SELECT @IdDownload = Dow_Id , @Path = Path  from DownloadLinks where FileName = @FileName and IsDisable = 0 and IsAudio = @IsAudio
      
                  if @IdDownload IS NULL
                        BEGIN             
                              INSERT INTO DownloadLinks (FileName,  TimeToVisit, IsDisable, IsAudio)  OUTPUT inserted.Dow_Id INTO @downloadTable
                              VALUES (@FileName, GETDATE(), 0, @IsAudio)                                    
                              select  @IdDownload= Dow_Id  from @downloadTable                  
                              select @Path = @Path + N'/' + CAST( @IdDownload AS VARCHAR(max)) + N'.' +  (RIGHT(@FileName, Len(@FileName)- Charindex('.', @FileName)))--  REPLACE(@Path, @FileName, @id)                
                              UPDATE   DownloadLinks SET  Path = @Path WHERE  (Dow_Id = @IdDownload)
                                    Set @IsUpdate = 1
    
                        END
                        else
                              BEGIN
                              Set @IsUpdate = 0
                              UPDATE   DownloadLinks SET  TimeToVisit = GETDATE() WHERE  (Dow_Id = @IdDownload)
                              END

            END
GO
/****** Object:  StoredProcedure [dbo].[Download_LinkDelete]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Download_LinkDelete]  
                @id uniqueidentifier
            AS
            BEGIN
                DELETE FROM DownloadLinks where Dow_Id = @id
            END
GO
/****** Object:  StoredProcedure [dbo].[Download_LinkDisable]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Download_LinkDisable] AS      
                  BEGIN 
                        UPDATE  DownloadLinks SET    IsDisable = 'True' 
                              where TimeToVisit <=  DATEADD (mi , 10 , TimeToVisit) 
                  END
GO
/****** Object:  StoredProcedure [dbo].[Download_LinkRemove]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Download_LinkRemove] 
                  AS    
                  BEGIN       
                        DELETE FROM DownloadLinks           
                              WHERE (IsDisable = 1) AND (TimeToVisit <=  DATEADD (mi , 20 , TimeToVisit))   
                  END
            
GO
/****** Object:  StoredProcedure [dbo].[ELMAH_GetErrorsXml]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE[dbo].[ELMAH_GetErrorsXml]  
  
                (  
                    @Application NVARCHAR(60),  
                    @PageIndex INT = 0,  
                    @PageSize INT = 15,  
                    @TotalCount INT OUTPUT  
  
                )    
                AS    
                SET NOCOUNT ON    
                DECLARE @FirstTimeUTC DATETIME  
                DECLARE @FirstSequence INT  
                DECLARE @StartRow INT  
                DECLARE @StartRowIndex INT  
                SELECT    
                @TotalCount = COUNT(1)   
                FROM    
                    [ELMAH_Error]    
                WHERE    
                    [Application] = @Application  
                SET @StartRowIndex = @PageIndex * @PageSize + 1  
                IF @StartRowIndex <= @TotalCount    
                BEGIN    
                SET ROWCOUNT @StartRowIndex    
                SELECT    
                @FirstTimeUTC = [TimeUtc],    
                    @FirstSequence = [Sequence]   
                FROM    
                    [ELMAH_Error]    
                WHERE    
                    [Application] = @Application   
                ORDER BY    
                    [TimeUtc] DESC,  
                    [Sequence] DESC    
                END    
                ELSE    
                BEGIN    
                SET @PageSize = 0   
                END    
                SET ROWCOUNT @PageSize   
                SELECT    
                errorId = [ErrorId],    
                    application = [Application],  
                    host = [Host],  
                    type = [Type],  
                    source = [Source],  
                    message = [Message],  
                    [user] = [User],  
                    statusCode = [StatusCode],  
                    time = CONVERT(VARCHAR(50), [TimeUtc], 126) + 'Z'  
  
                FROM    
                    [ELMAH_Error] error    
                WHERE    
                    [Application] = @Application  
                AND    
                    [TimeUtc] <= @FirstTimeUTC    
                AND    
                    [Sequence] <= @FirstSequence    
                ORDER BY    
                    [TimeUtc] DESC,   
                    [Sequence] DESC    
                FOR    
                XML AUTO  
GO
/****** Object:  StoredProcedure [dbo].[ELMAH_GetErrorXml]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE[dbo].[ELMAH_GetErrorXml]  
  
                (  
  
                    @Application NVARCHAR(60),  
                    @ErrorId UNIQUEIDENTIFIER  
  
                )  
  
                AS  
  
                SET NOCOUNT ON  
                SELECT  
  
                    [AllXml]  
                FROM  
  
                    [ELMAH_Error]  
                WHERE  
  
                    [ErrorId] = @ErrorId  
                AND  
                    [Application] = @Application  
GO
/****** Object:  StoredProcedure [dbo].[ELMAH_LogError]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE[dbo].[ELMAH_LogError]  
                (    
                    @ErrorId UNIQUEIDENTIFIER,    
                    @Application NVARCHAR(60),    
                    @Host NVARCHAR(30),    
                    @Type NVARCHAR(100),  
                    @Source NVARCHAR(60),    
                    @Message NVARCHAR(500),  
                    @User NVARCHAR(50),   
                    @AllXml NTEXT,    
                    @StatusCode INT,   
                    @TimeUtc DATETIME    
                )    
                AS 
                SET NOCOUNT ON    
                INSERT    
                INTO    
                    [ELMAH_Error](    
                    [ErrorId],   
                    [Application],   
                    [Host],  
                    [Type],  
                    [Source],  
                    [Message],    
                    [User],    
                    [AllXml],    
                    [StatusCode],    
                    [TimeUtc]   
                )    
                VALUES  
                    (   
                    @ErrorId,  
                    @Application,    
                    @Host,    
                    @Type,    
                    @Source,   
                    @Message,    
                    @User,   
                    @AllXml,   
                    @StatusCode,   
                    @TimeUtc  
  
                )
GO
/****** Object:  StoredProcedure [dbo].[GetAll]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetAll]
      @uuid NVARCHAR(MAX)
AS
BEGIN
      INSERT INTO [dbo].[UserLogs] (UsL_UUId, UsL_DateTime)
      VALUES (@uuid, getdate())

      SELECT [dbo].[GetLastUpdate]() AS LastUpdate

      SELECT * FROM [dbo].AllPlaces() AS Places

      SELECT * FROM [dbo].AllAudios() AS Audios
      WHERE Audios.PlaceId IN
            (SELECT Id FROM [dbo].AllPlaces())
      
      SELECT * FROM [dbo].AllStories() AS Stories
      WHERE Stories.PlaceId IN
            (SELECT Id FROM [dbo].AllPlaces())
      
      SELECT * FROM [dbo].AllImages() AS Images
      WHERE Images.PlaceId IN
            (SELECT Id FROM [dbo].AllPlaces())
            
      SELECT * FROM [dbo].AllTips() AS Tips
      WHERE Tips.PlaceId IN
            (SELECT Id FROM [dbo].AllPlaces())

      SELECT * FROM [dbo].AllCities()

      SELECT * FROM [dbo].AllTipCategories()
END
GO
/****** Object:  StoredProcedure [dbo].[GetAll_v2]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetAll_v2]
                  @uuid NVARCHAR(MAX)
            AS
            BEGIN
                  INSERT INTO [dbo].[UserLogs] (UsL_UUId, UsL_DateTime)
                  VALUES (@uuid, getdate())

                  SELECT [dbo].[GetLastUpdate_v2]() AS LastUpdate
                  SELECT * INTO #Places FROM (SELECT * FROM [dbo].AllPlaces_v2()) AS Places
                  SELECT  * FROM #Places AS Places

                  SELECT * FROM [dbo].AllAudios_v2() AS Audios
                  WHERE Audios.PlaceId IN       (select Id from #Places)
      
                  SELECT * FROM [dbo].AllStories_v2() AS Stories
                  WHERE Stories.PlaceId IN      (select Id from #Places)
      
                  SELECT * FROM [dbo].AllImages_v2() AS Images
                  WHERE Images.PlaceId IN       (select Id from #Places)
            
                  SELECT * FROM [dbo].AllTips_v2() AS Tips
                  WHERE Tips.PlaceId IN (select Id from #Places)

                  SELECT * FROM [dbo].AllCities_v2()

                  SELECT * FROM [dbo].AllTipCategories_v2()


                  SELECT * FROM [dbo].AllTranslateCities_v2() AS TranslateCities

                  SELECT * FROM [dbo].AllTranslateImages_v2() AS TranslateImages

                  SELECT * FROM [dbo].AllTranslatePlaces_v2() AS TranslatePlaces

            END
GO
/****** Object:  StoredProcedure [dbo].[GetAutorizedCities]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetAutorizedCities]
      @UserID AS nvarchar(128)
AS
BEGIN
      SET NOCOUNT ON;

    SELECT Packagecities.city_Cit_Id AS cityID
      FROM Procurements INNER JOIN
             Packagecities ON Procurements.Pac_Id = Packagecities.Package_Pac_Id
     WHERE 
             (Procurements.Id = @UserID) AND (Pro_PaymentFinished = 1)
     GROUP BY Packagecities.city_Cit_Id

END
GO
/****** Object:  StoredProcedure [dbo].[GetAutorizedCities_v2]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetAutorizedCities_v2]
                  @UserID AS nvarchar(128)
            AS
            BEGIN
                  SET NOCOUNT ON;           

                    SELECT        Packagecities.city_Cit_Id AS cityID , Packages.langId as langId
                    FROM            Procurements INNER JOIN
                                Packagecities ON Procurements.Pac_Id = Packagecities.Package_Pac_Id INNER JOIN
                                Packages ON Procurements.Pac_Id = Packages.Pac_Id AND Packagecities.Package_Pac_Id = Packages.Pac_Id
                    WHERE        (Procurements.Id = @UserID) AND (Procurements.Pro_PaymentFinished = 1)
                    GROUP BY Packagecities.city_Cit_Id , Packages.langId 

            END
GO
/****** Object:  StoredProcedure [dbo].[GetPackages]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetPackages]
      @CityId int
AS
BEGIN
      DECLARE @Packages TABLE 
      (
            Id uniqueidentifier,
            Name nvarchar(MAX),
            Price bigint,
            PriceD float
      )
      DECLARE @Cities TABLE 
      (
            Id INT
      )
      DECLARE @ResultCities TABLE 
      (
            Id INT,
            AudioCount INT,
            StoryCount INT
      )
      DECLARE @PackageCities TABLE 
      (
            Id INT,
            CityName NVARCHAR(MAX),
            PlacesCount INT,
            AudiosCount INT,
            StoriesCount INT
      )

      INSERT @Packages
      SELECT dbo.Packages.Pac_Id, dbo.Packages.Pac_Name, dbo.Packages.Pac_Price, dbo.Packages.Pac_Price_Dollar
        FROM dbo.Packagecities INNER JOIN
                        dbo.Packages ON dbo.Packagecities.Package_Pac_Id = dbo.Packages.Pac_Id
       WHERE dbo.Packagecities.city_Cit_Id = @CityId
       
      INSERT @Cities
      SELECT DISTINCT city_Cit_Id
      FROM  dbo.Packagecities 
      WHERE Package_Pac_Id IN 
            (SELECT Id FROM @Packages)

      DECLARE @TempCityId INT

      DECLARE City_CURSOR CURSOR 
        LOCAL STATIC READ_ONLY FORWARD_ONLY
      FOR 
      SELECT DISTINCT Id
      FROM @Cities
      
      OPEN City_CURSOR
      FETCH NEXT FROM City_CURSOR INTO @TempCityId
      WHILE @@FETCH_STATUS = 0
      BEGIN 
            INSERT @ResultCities
            SELECT @TempCityId, dbo.AudiosCount(P.Id), dbo.StoriesCount(P.Id)
            FROM dbo.AllPlacesId(@TempCityId) AS P
            GROUP BY P.Id

            FETCH NEXT FROM City_CURSOR INTO @TempCityId
      END
      CLOSE City_CURSOR
      DEALLOCATE City_CURSOR
      
      INSERT @PackageCities
      SELECT Id, dbo.cities.Cit_Name, COUNT(*), SUM(AudioCount), SUM(StoryCount)
      FROM @ResultCities INNER JOIN
      dbo.cities ON dbo.cities.Cit_Id = Id
      GROUP BY Id, dbo.cities.Cit_Name

      SELECT * 
      FROM @Packages

      SELECT Package_Pac_Id AS PackageId, Id As CityId, CityName, PlacesCount, AudiosCount, StoriesCount
      FROM dbo.Packagecities right join
      @PackageCities ON city_Cit_Id = Id
      WHERE Package_Pac_Id IN (SELECT Id FROM @Packages)
END
GO
/****** Object:  StoredProcedure [dbo].[GetPackages_v2]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetPackages_v2]
                  @CityId int,
                  @langId int 
            AS
            BEGIN
      
                  DECLARE @Packages TABLE 
                  (
                        Id uniqueidentifier,
                        Name nvarchar(MAX),
                        Price bigint,
                        PriceD float
                  )
                  DECLARE @Cities TABLE 
                  (
                        Id INT
                  )
                  DECLARE @ResultCities TABLE 
                  (
                        Id INT,
                        AudioCount INT,
                        StoryCount INT
                  )
                  DECLARE @PackageCities TABLE 
                  (
                        Id INT,
                        CityName NVARCHAR(MAX),
                        PlacesCount INT,
                        AudiosCount INT,
                        StoriesCount INT
                  )

                  INSERT @Packages
                  SELECT dbo.Packages.Pac_Id, dbo.Packages.Pac_Name, dbo.Packages.Pac_Price, dbo.Packages.Pac_Price_Dollar
                    FROM dbo.Packagecities INNER JOIN
                                    dbo.Packages ON dbo.Packagecities.Package_Pac_Id = dbo.Packages.Pac_Id
                   WHERE dbo.Packagecities.city_Cit_Id = @CityId and Packages.langId = @langId
       
                  INSERT @Cities
                  SELECT DISTINCT city_Cit_Id
                  FROM  dbo.Packagecities 
                  WHERE Package_Pac_Id IN 
                        (SELECT Id FROM @Packages)

                  DECLARE @TempCityId INT

                  DECLARE City_CURSOR CURSOR 
                    LOCAL STATIC READ_ONLY FORWARD_ONLY
                  FOR 
                  SELECT DISTINCT Id
                  FROM @Cities
      
                  OPEN City_CURSOR
                  FETCH NEXT FROM City_CURSOR INTO @TempCityId
                  WHILE @@FETCH_STATUS = 0
                  BEGIN 
                        INSERT @ResultCities
                        SELECT @TempCityId, dbo.AudiosCount_v2(P.Id, @langId), dbo.StoriesCount_v2(P.Id, @langId)
                        FROM dbo.AllPlacesId_v2(@TempCityId) AS P
                        GROUP BY P.Id

                        FETCH NEXT FROM City_CURSOR INTO @TempCityId
                  END
                  CLOSE City_CURSOR
                  DEALLOCATE City_CURSOR
      
                  INSERT @PackageCities
                  SELECT Id, dbo.TranslateCities.TrC_Name, COUNT(*), SUM(AudioCount), SUM(StoryCount)
                  FROM @ResultCities INNER JOIN
                  dbo.cities ON dbo.cities.Cit_Id = Id      
                  INNER JOIN  TranslateCities ON TranslateCities.Cit_Id = Id
                  where TranslateCities.langId = @langId

                  GROUP BY Id, dbo.TranslateCities.TrC_Name

                  SELECT * 
                  FROM @Packages

                  SELECT Package_Pac_Id AS PackageId, Id As CityId, CityName, PlacesCount, AudiosCount, StoriesCount
                  FROM dbo.Packagecities right join
                  @PackageCities ON city_Cit_Id = Id
                  WHERE Package_Pac_Id IN (SELECT Id FROM @Packages)
            END
GO
/****** Object:  StoredProcedure [dbo].[GetPackages_website]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetPackages_website]
    @langId int
AS
BEGIN
 
DECLARE @Packages TABLE  
(
      PackageId  UNIQUEIDENTIFIER ,
      PackageName NVARCHAR(MAX),
      PackagePrice bigint,
      PackagePriceDollar real,
      PackageOrder INT,
      CityId  int ,
      CityName NVARCHAR(MAX),
      CityOrder INT,
      CityImgUrl nvarchar(max),
      CityDescription nvarchar(max)

)
INSERT @Packages
      SELECT  Packages.Pac_Id,
            Packages.Pac_Name,
            Packages.Pac_Price,
            Packages.Pac_Price_Dollar,
            Packages.Pac_Order,
            cities.Cit_Id,
            TranslateCities.TrC_Name,
            cities.Cit_Order,
                  cities.Cit_ImageUrl,
                  cities.Cit_Description
      FROM    Packages 
                  INNER JOIN Packagecities ON Packages.Pac_Id = Packagecities.Package_Pac_Id 
                  INNER JOIN cities ON Packagecities.city_Cit_Id = cities.Cit_Id 
                  INNER JOIN TranslateCities ON cities.Cit_Id = TranslateCities.Cit_Id
                  WHERE Packages.langId = @langId and TranslateCities.langId =@langId  and cities.Cit_Name IS NOT NULL 
                                     


                                     
DECLARE @Places TABLE 
(     
      Pla_Id UNIQUEIDENTIFIER,
      Name  NVARCHAR(MAX),
      Discription  NVARCHAR(MAX),
      Address  NVARCHAR(MAX),
      ImgUrl  NVARCHAR(MAX),
      TumbImgUrl  NVARCHAR(MAX),
      AudiosCount INT,
      StoriesCount INT,
      Cit_Id INT,
      OrderItem  INT
)
   INSERT @Places
            SELECT 
                    Places.Pla_Id,
                    TranslatePlaces.TrP_Name,
                    TranslatePlaces.TrP_Description,
                    TranslatePlaces.TrP_Address,
                    Places.Pla_ImgUrl,
                    Places.Pla_TumbImgUrl ,
                    dbo.AudiosCount_v2(Places.Pla_Id,@langId),
                    dbo.StoriesCount_v2(Places.Pla_Id,@langId),
                    Pla_city_Cit_Id,
                    Pla_Order

            FROM  Places 
                    INNER JOIN TranslatePlaces ON Places.Pla_Id = TranslatePlaces.Pla_Id 
            WHERE TranslatePlaces.langId = @langId 
            and Pla_isOnline = 1 
            and Pla_Deactive = 0
             and TranslatePlaces.TrP_Name IS NOT NULL 
                                     
                                     
                                     
SELECT * fROM @Places
SELECT * FROM @Packages
END



GO
/****** Object:  StoredProcedure [dbo].[GetPackagesProcurements_website]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetPackagesProcurements_website]
    @Username Nvarchar(max)
AS
BEGIN 
      SELECT   Procurements.Pac_Id as Pac_Id
      FROM            Procurements INNER JOIN  AspNetUsers ON Procurements.Id = AspNetUsers.Id
      Where             AspNetUsers.UserName =@Username 
                              and   Procurements.Pro_PaymentFinished = 1                                    
END

GO
/****** Object:  StoredProcedure [dbo].[GetUpdates]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetUpdates]
      @UpdateNumber AS INT,
      @uuid NVARCHAR(MAX)
AS
BEGIN
      INSERT INTO [dbo].[UserLogs] (UsL_UUId, UsL_DateTime)
      VALUES (@uuid, getdate())

      SELECT [dbo].[GetLastUpdate]() AS LastUpdate
      --GETING NEW ENTITIES
      SELECT * FROM [dbo].AllPlaces() p
      WHERE p.Id IN
      (
            SELECT Pla_ID
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 0
      )

      SELECT * FROM [dbo].AllAudios() a
      WHERE a.Id IN
      (
            SELECT Aud_Id
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Aud_Id IS NOT NULL AND isRemoved = 0
      ) OR a.PlaceId IN
      (
            SELECT Pla_ID
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 0
      )
      
      SELECT * FROM [dbo].AllStories() s
      WHERE s.Id IN
      (
            SELECT Sto_Id
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Sto_Id IS NOT NULL AND isRemoved = 0
      ) OR s.PlaceId IN
      (
            SELECT Pla_ID
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 0
      )

      SELECT * FROM [dbo].AllImages() i
      WHERE i.Id IN
      (
            SELECT Img_ID
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Img_ID IS NOT NULL AND isRemoved = 0
      ) OR i.PlaceId IN
      (
            SELECT Pla_ID
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 0
      )

      SELECT * FROM [dbo].AllTips() t
      WHERE t.Id IN
      (
            SELECT Tip_ID
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Tip_ID IS NOT NULL AND isRemoved = 0
      ) OR t.PlaceId IN
      (
            SELECT Pla_ID
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 0
      )

      SELECT * FROM [dbo].AllCities() c
      WHERE c.Id IN
      (
            SELECT Cit_ID
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Cit_ID IS NOT NULL AND isRemoved = 0
      )
      --GETING REMOVED ENTITIES
      SELECT Pla_ID AS Id
      FROM [dbo].[UpdateLogs]
      WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 1

      SELECT Aud_Id AS Id
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Aud_Id IS NOT NULL AND isRemoved = 1
      
      --SELECT a.Id AS Id FROM [dbo].AllAudios() a
      --WHERE a.Id IN
      --(
            
      --) OR a.PlaceId IN
      --(
      --    SELECT Pla_ID
      --    FROM [dbo].[UpdateLogs]
      --    WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 1
      --)
      
      SELECT Sto_Id AS Id
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Sto_Id IS NOT NULL AND isRemoved = 1

      --SELECT s.Id AS Id FROM [dbo].AllStories() s
      --WHERE s.Id IN
      --(
      --    SELECT Sto_Id
      --    FROM [dbo].[UpdateLogs]
      --    WHERE UpL_Id > @UpdateNumber AND Sto_Id IS NOT NULL AND isRemoved = 1
      --) OR s.PlaceId IN
      --(
      --    SELECT Pla_ID
      --    FROM [dbo].[UpdateLogs]
      --    WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 1
      --)
      SELECT Img_ID AS Id
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Img_ID IS NOT NULL AND isRemoved = 1

      --SELECT i.Id AS Id FROM [dbo].AllImages() i
      --WHERE i.Id IN
      --(
            
      --) OR i.PlaceId IN
      --(
      --    SELECT Pla_ID
      --    FROM [dbo].[UpdateLogs]
      --    WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 1
      --)

      SELECT Tip_ID AS Id
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Tip_ID IS NOT NULL AND isRemoved = 1

      --SELECT t.Id AS Id FROM [dbo].AllTips() t
      --WHERE t.Id IN
      --(
      --    SELECT Tip_ID
      --    FROM [dbo].[UpdateLogs]
      --    WHERE UpL_Id > @UpdateNumber AND Tip_ID IS NOT NULL AND isRemoved = 1
      --) OR t.PlaceId IN
      --(
      --    SELECT Pla_ID
      --    FROM [dbo].[UpdateLogs]
      --    WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 1
      --)
      SELECT Cit_ID  AS Id
            FROM [dbo].[UpdateLogs]
            WHERE UpL_Id > @UpdateNumber AND Cit_ID IS NOT NULL AND isRemoved = 1

      --SELECT c.Id AS Id FROM [dbo].AllCities() c
      --WHERE c.Id IN
      --(
      --    SELECT Cit_ID
      --    FROM [dbo].[UpdateLogs]
      --    WHERE UpL_Id > @UpdateNumber AND Cit_ID IS NOT NULL AND isRemoved = 1
      --)
END
GO
/****** Object:  StoredProcedure [dbo].[GetUpdates_v2]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetUpdates_v2]
                  @UpdateNumber AS INT,
                  @uuid NVARCHAR(MAX)
            AS
            BEGIN
                        INSERT INTO [dbo].[UserLogs] (UsL_UUId, UsL_DateTime)
                        VALUES (@uuid, getdate())

                        SELECT [dbo].[GetLastUpdate_v2]() AS LastUpdate
                        --GETING NEW ENTITIES
      
      
                        SELECT * FROM [dbo].AllPlaces_v2() p
                        WHERE p.Id IN
                        (
                              SELECT Pla_ID
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 0
                        )
      
      
                        SELECT * FROM [dbo].AllTranslatePlaces_v2() p
                        WHERE p.Id IN
                        (
                              SELECT TrP_Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND TrP_Id IS NOT NULL AND isRemoved = 0
                        )
      
                        SELECT * FROM [dbo].AllTranslateCities_v2() p
                        WHERE p.Id IN
                        (
                              SELECT TrC_Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND TrC_Id IS NOT NULL AND isRemoved = 0
                        )
      
      
                        SELECT * FROM [dbo].AllTranslateImages_v2() p
                        WHERE p.Id IN
                        (
                              SELECT TrI_Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND TrI_Id IS NOT NULL AND isRemoved = 0
                        )
      
      
                        SELECT * FROM [dbo].AllAudios_v2() a
                        WHERE a.Id IN
                        (
                              SELECT Aud_Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND Aud_Id IS NOT NULL AND isRemoved = 0
                        )
      
                        SELECT * FROM [dbo].AllStories_v2() s
                        WHERE s.Id IN
                        (
                              SELECT Sto_Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND Sto_Id IS NOT NULL AND isRemoved = 0
                        ) 

      
                        SELECT * FROM [dbo].AllImages_v2() i
                        WHERE i.Id IN
                        (
                              SELECT Img_ID
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND Img_ID IS NOT NULL AND isRemoved = 0
                        ) 

      
                        SELECT * FROM [dbo].AllTips_v2() t
                        WHERE t.Id IN
                        (
                              SELECT Tip_ID
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND Tip_ID IS NOT NULL AND isRemoved = 0
                        )
      
                        SELECT * FROM [dbo].AllCities_v2() c
                        WHERE c.Id IN
                        (
                              SELECT Cit_ID
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND Cit_ID IS NOT NULL AND isRemoved = 0
                        )
      
      
                        --GETING REMOVED ENTITIES
                        SELECT Pla_ID AS Id
                        FROM [dbo].[UpdateLogs]
                        WHERE UpL_Id > @UpdateNumber AND Pla_ID IS NOT NULL AND isRemoved = 1

      
                              SELECT Aud_Id AS Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND Aud_Id IS NOT NULL AND isRemoved = 1
      
                        --SELECT a.Id AS Id FROM [dbo].AllAudios_v2() a
                        --WHERE a.Id IN
                        --(
                        --)
      
                        SELECT Sto_Id AS Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND Sto_Id IS NOT NULL AND isRemoved = 1
      
                        --SELECT s.Id AS Id FROM [dbo].AllStories_v2() s
                        --WHERE s.Id IN
                        --(
                      
                        --) 

                              SELECT Img_ID AS Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND Img_ID IS NOT NULL AND isRemoved = 1
      
                        --SELECT i.Id AS Id FROM [dbo].AllImages_v2() i
                        --WHERE i.Id IN
                        --(
                        --) 

                              SELECT Tip_ID AS Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND Tip_ID IS NOT NULL AND isRemoved = 1
      
                        --SELECT t.Id AS Id FROM [dbo].AllTips_v2() t
                        --WHERE t.Id IN
                        --(
                        --) 


                              SELECT Cit_ID AS Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND Cit_ID IS NOT NULL AND isRemoved = 1
      
                        --SELECT c.Id AS Id FROM [dbo].AllCities_v2() c
                        --WHERE c.Id IN
                        --(
                        --)


      
                              SELECT TrP_Id AS Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND TrP_Id IS NOT NULL AND isRemoved = 1
                        --SELECT c.Id AS Id FROM [dbo].AllTranslatePlaces_v2() c
                        --WHERE c.Id IN
                        --(
                        --)

      
                              SELECT TrC_Id  AS Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND TrC_Id IS NOT NULL AND isRemoved = 1
                        --SELECT c.Id AS Id FROM [dbo].AllTranslateCities_v2() c
                        --WHERE c.Id IN
                        --(
                        --)
      
                              SELECT TrI_Id AS Id
                              FROM [dbo].[UpdateLogs]
                              WHERE UpL_Id > @UpdateNumber AND TrI_Id IS NOT NULL AND isRemoved = 1
                        --SELECT c.Id AS Id FROM [dbo].AllTranslateImages_v2() c
                        --WHERE c.Id IN
                        --(
                        --)
                END
GO
/****** Object:  StoredProcedure [dbo].[InsertTranclate]    Script Date: 5/16/2017 2:49:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[InsertTranclate]
AS
BEGIN
DECLARE @langId int = 1

UPDATE [dbo].[Packages]  SET  [langId] =@langId

INSERT INTO [dbo].[TranslateCities]
           ([TrC_Name]
           ,[TrC_Description]
           ,[Cit_Id]
           ,[langId])
   
SELECT Cit_Name, Cit_Description, Cit_Id, @langId from cities



INSERT INTO [dbo].[TranslateImages]
           ([TrI_Name]
           ,[TrI_Description]
           ,[Img_Id]
           ,[langId])
   
SELECT Img_Name, Img_Description, Img_Id, @langId from Images


INSERT INTO [dbo].[TranslatePlaces]
           ([TrP_Name]
           ,[TrP_Description]
           ,[TrP_Address]
           ,[Pla_Id]
           ,[langId])
SELECT  Pla_Name,Pla_Discription,Pla_Address,Pla_Id, @langId from Places
if(@langId = 1)
begin

UPDATE [dbo].[Stories]  SET [langId] = @langId;

UPDATE [dbo].[Audios]  SET [langId] = @langId;



UPDATE [dbo].[Tips]   SET [langId] = @langId;
end
END

GO
