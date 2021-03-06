﻿//Developed by Soroosh Ansari
angular.module('AdminPage.controllers', [])
    .directive('myEnter', function () {
        return function (scope, element, attrs) {
            element.bind("keydown keypress", function (event) {
                if (event.which === 13) {
                    scope.$apply(function () {
                        scope.$eval(attrs.myEnter);
                    });

                    event.preventDefault();
                }
            });
        };
    })
    .controller('AdminController', ['$scope', '$rootScope', '$sce', 'PlaceServices', 'CityServices', 'AudioServices', 'TipServices', 'StoryServices', 'PackageServices',
        function ($scope, $rootScope, $sce, PlaceServices, CityServices, AudioServices, TipServices, StoryServices, PackageServices) {
            //global
            var placePaging = 10;
            var paging = 5;
            var validImgFormats = ['jpg', 'png', 'jpeg'];
            var validAudioFormats = ['mp3'];
            $scope.finishSaveImageGallery = true;
            $scope.finishSaveImageExtra = true;

            var getImages = function (placeId, type) {
                PlaceServices.GetExtraImages(placeId, type).
                    then(function (response) {
                        if (type == 0) {
                            $scope.selectedPlace.ExtraImages = response.data;
                            $scope.finishSaveImageExtra = true;

                        }
                        else {
                            $scope.selectedPlace.GalleryImages = response.data;
                            $scope.finishSaveImageGallery = true;
                        }
                    }, function (response) {
                        notific.error("ERROR", "Request failed");
                    });
            }
            $rootScope.hide = function (modal) {
                $(modal).modal('hide');
            }
            $rootScope.ShowOverlay = false;
            $rootScope.NewStoryShowOverlay = false;
            $rootScope.EditOverlay = false;
            function scroll(id) {
                var dest = 0;
                if ($(id).offset().top > $(document).height() - $(window).height()) {
                    dest = $(document).height() - $(window).height();
                } else {
                    dest = $(id).offset().top;
                }
                //go to destination
                $('html,body').animate({
                    scrollTop: dest
                }, 2000, 'swing');
            };
            $scope.SetImageName = function (o) {
                NewPlaceForm.imgUrl.value = o.files[0].name;
            }
            $scope.selectCityImg = false;
            $scope.SetCityImageName = function (o) {
                NewCityForm.cityImgUrl.value = o.files[0].name;
                $scope.selectCityImg = true;
            }
            $scope.saveOrderExtraImg = function (model) {
                model.isLoading = true;
                PlaceServices.SaveOrder(model).then(function (resault) {
                    try {
                        
                        getImages(model.PlaceId, model.Type);
                    }
                    catch(error){
                        $('#EditPlaceModal').modal('hide');
                    }
                }, function () {
                    $('#EditPlaceModal').modal('hide');
                    //$rootScope.saveOrderBtn = false;

                });
            }


            //Edit Place
            $scope.OnlineEditPlaceVM;


            //Story and Audio Stuff
            $scope.LoadPlaceAudiosAndStories = function (placeId) {
                $scope.LoadPlaceStorys(placeId);
                $scope.LoadPlaceAudios(placeId);
                for (var i = 0; i < $scope.places.length; i++) {
                    if ($scope.places[i].PlaceId == placeId) {
                        $scope.places[i].selected = true;
                    }
                    else
                        $scope.places[i].selected = false;
                }
            };
            //Story Player stuff
            $scope.StoryTitle = "...";
            $rootScope.Storys;
            $scope.StoryPlayStatus = "play";
            var playingIndex;
            //$scope.timeElapsed = "";
            //$scope.StoryProgress = 0;
            var Story;
            var StoryStatus = "empty"; //empty, play, puase
            $scope.LoadPlaceStorys = function (PlaceId) {
                $scope.selectedPlaceId = PlaceId;
                $scope.StoryTitle = "...";
                StoryStatus = "empty";
                StoryServices.Get(PlaceId);
                //scroll("#Player");
            };
            $scope.$on('FillFirstStory', function (event) {
                $scope.loadStory(1);
            });
            $scope.loadStory = function (StoryIndex) {
                playingIndex = StoryIndex;
                angular.forEach($rootScope.Storys, function (value, key) {
                    if (value.Index == StoryIndex) {
                        //  todo test getUrl
                        var m = {
                            trackId: value.Id,
                            isAudio: false
                        }
                        PlaceServices.getUrl(m);
                        if (StoryStatus != "empty") {
                            Story.pause();
                            $scope.StoryPlayStatus = "play";
                        }
                        $scope.StoryTitle = value.Name;
                        //var src = "../Stories/" + value.Url;
                        var src = value.Url;
                        Story = new Audio(src);
                        StoryStatus = "pause";
                        console.log(src);
                        return;
                    }
                });
            }
            $scope.Story_Play = function () {
                switch (StoryStatus) {
                    case "empty":
                        break;
                    case "play":
                        //clearInterval(timer);
                        Story.pause();
                        //$scope.timeElapsed = "";
                        //$scope.StoryProgress = 0;
                        $scope.StoryPlayStatus = "play";
                        StoryStatus = "pause";
                        break;
                    case "pause":
                        Story.play();
                        //var timer = setInterval(updateProgress, 1000);
                        $scope.StoryPlayStatus = "pause";
                        StoryStatus = "play";
                        break;
                    default:

                }
            };
            $scope.Story_prev = function () {
                if (playingIndex > 1) {
                    if (StoryStatus == "play")
                        $scope.Story_Play(); //first pause the playing Story
                    $scope.loadStory(playingIndex - 1);
                    $scope.Story_Play();
                }
            };
            $scope.Story_next = function () {
                if ($rootScope.Storys.length > playingIndex) {
                    if (StoryStatus == "play")
                        $scope.Story_Play(); //first pause the playing Story
                    $scope.loadStory(playingIndex + 1);
                    $scope.Story_Play();
                }
            };

            //Story Stuff
            $scope.NewStory = function () {
                console.log("hi");
                $('#NewStoryModal').modal('show');
            };
            $scope.SetStoryName = function (o) {
                $scope.NewStoryVM.FileChanged = true;
                var StoryUrl = o.files[0].name;
                var ext = StoryUrl.substring(StoryUrl.lastIndexOf('.') + 1).toLowerCase();
                if (validAudioFormats.indexOf(ext) !== -1) {
                    NewStoryForm.StoryUrl.value = StoryUrl;
                    $scope.NewStoryVM.invalidFile = false;
                }
                else {
                    NewStoryForm.StoryUrl.value = '';
                    $scope.NewStoryVM.invalidFile = true;
                }
            }
            $scope.AddStory = function (model, form) {

                if (form.$valid && !model.invalidFile) {
                    $rootScope.NewStoryShowOverlay = true;
                    StoryServices.Add(model, $scope.selectedPlaceId);
                }
            };
            $scope.removeStory = function (StoryId) {
                StoryServices.Remove(StoryId);
            }
            $scope.$on('UpdateStorys', function (event) {
                $scope.LoadPlaceStorys($scope.selectedPlaceId);
            });
            $scope.$on('UpdateStoryValidationSummery', function (event, args) {
                //$scope.additionalError = args.data;
                //scroll("#NewPlace");
            });
            $scope.$on('RemoveStoryError', function (event, args) {
                $scope.ForignKeyErrorBody = 'Error on removing story.<br/>' + args.content + '<br/>Contact site developer to get more information.'
                $scope.DelSubsBtn = "hidden";
                $('#ForignKeyErrorModal').modal('show');
            });
            $scope.$on('LoadFirstPlaceStorys', function (event) {
                if ($scope.places.length > 0) {
                    $scope.LoadPlaceStorys($scope.places[0].PlaceId);
                }
            });



            //Player stuff
            $scope.selectedPlaceId;
            $rootScope.placeimage = "/Content/images/160x100.png";
            $scope.AudioTitle = "...";
            $rootScope.audios;
            $scope.PlayStatus = "play";
            var playingIndex;
            //$scope.timeElapsed = "";
            //$scope.audioProgress = 0;
            var audio;
            var audioStatus = "empty"; //empty, play, puase
            $scope.LoadPlaceAudios = function (PlaceId) {
                $scope.selectedPlaceId = PlaceId;
                $scope.AudioTitle = "...";
                audioStatus = "empty";
                AudioServices.Get(PlaceId);
                //scroll("#Player");
            };
            $scope.$on('FillFirstAudio', function (event) {
                $scope.loadAudio(1);
            });
            $scope.loadAudio = function (audioIndex) {

                playingIndex = audioIndex;
                angular.forEach($rootScope.audios, function (value, key) {
                    if (value.Index == audioIndex) {
                        $scope.AudioTitle = value.Aud_Name;
                        //var src = "../Audios/" + value.Aud_Url;
                        var src = value.Aud_Url;
                        audio = new Audio(src);
                        audioStatus = "pause";
                        return;

                        if (audioStatus != "empty") {
                            audio.pause();
                            $scope.PlayStatus = "play";
                        }

                    }
                });
            }
            $scope.Audio_Play = function () {
                switch (audioStatus) {
                    case "empty":
                        break;
                    case "play":
                        //clearInterval(timer);
                        audio.pause();
                        //$scope.timeElapsed = "";
                        //$scope.audioProgress = 0;
                        $scope.PlayStatus = "play";
                        audioStatus = "pause";
                        break;
                    case "pause":
                        audio.play();
                        //var timer = setInterval(updateProgress, 1000);
                        $scope.PlayStatus = "pause";
                        audioStatus = "play";
                        break;
                    default:

                }
            };
            $scope.Audio_prev = function () {
                if (playingIndex > 1) {
                    if (audioStatus == "play")
                        $scope.Audio_Play(); //first pause the playing audio
                    $scope.loadAudio(playingIndex - 1);
                    $scope.Audio_Play();
                }
            };
            $scope.Audio_next = function () {
                if ($rootScope.audios.length > playingIndex) {
                    if (audioStatus == "play")
                        $scope.Audio_Play(); //first pause the playing audio
                    $scope.loadAudio(playingIndex + 1);
                    $scope.Audio_Play();
                }
            };
            //Audio Stuff
            $scope.NewAudio = function () {
                $('#NewAudioModal').modal('show');
            };
            $scope.SetAudioName = function (o) {
                $scope.NewAudioVM.FileChanged = true;
                var AudioUrl = o.files[0].name;
                var ext = AudioUrl.substring(AudioUrl.lastIndexOf('.') + 1).toLowerCase();
                if (validAudioFormats.indexOf(ext) !== -1) {
                    NewAudioForm.AudioUrl.value = AudioUrl;
                    $scope.NewAudioVM.invalidFile = false;
                }
                else {
                    NewAudioForm.AudioUrl.value = '';
                    $scope.NewAudioVM.invalidFile = true;
                }
            }
            $scope.AddAudio = function (model, form) {
                if (form.$valid && !model.invalidFile) {
                    $rootScope.ShowOverlay = true;
                    AudioServices.Add(model, $scope.selectedPlaceId);
                }
            };
            $scope.removeAudio = function (audioId) {
                AudioServices.Remove(audioId);
            }
            $scope.$on('UpdateAudios', function (event) {
                $scope.LoadPlaceAudios($scope.selectedPlaceId);
            });
            $scope.$on('UpdateAudioValidationSummery', function (event, args) {
                //$scope.additionalError = args.data;
                //scroll("#NewPlace");
            });
            $scope.$on('RemoveAudioError', function (event, args) {
                $scope.ForignKeyErrorBody = 'Error on removing audio.<br/>' + args.content + '<br/>Contact site developer to get more information.'
                $scope.DelSubsBtn = "hidden";
                $('#ForignKeyErrorModal').modal('show');
            });
            $scope.$on('LoadFirstPlaceAudios', function (event) {
                if ($scope.places.length > 0) {
                    $scope.LoadPlaceAudios($scope.places[0].PlaceId);
                }
            });

            //Place stuff
            $scope.PlacePagesLen = 0;
            $scope.PlaceCurrentPage = 0;
            $rootScope.allPlaces = [];
            PlaceServices.GetAll();
            $scope.SwichPrimaryStatus = function (placeId) {
                PlaceServices.SwichPrimaryStatus(placeId);
            }
            $scope.$on('LoadPlaces', function (event) {
                $scope.places = angular.copy($rootScope.allPlaces.slice(0, placePaging));
                $scope.PlacePagesLen = Math.floor($rootScope.allPlaces.length / placePaging);
                if (($rootScope.allPlaces.length / placePaging > $scope.PlacePagesLen))
                    $scope.PlacePagesLen++;
            });
            $scope.NextPlace = function () {
                //if ($rootScope.PlacePagesLen - $rootScope.PlaceCurrentPage > 1)
                //    $scope.places = PlaceServices.Get($rootScope.PlaceCurrentPage + 1);
                if ($scope.PlacePagesLen - $scope.PlaceCurrentPage > 1) {
                    $scope.places = angular.copy($rootScope.allPlaces.slice(($scope.PlaceCurrentPage + 1) * placePaging, ($scope.PlaceCurrentPage + 2) * placePaging));
                    $scope.PlaceCurrentPage++;
                }
            };
            $scope.PreviousPlace = function () {
                //if ($rootScope.PlaceCurrentPage > 0)
                //    $scope.places = PlaceServices.Get($rootScope.PlaceCurrentPage - 1);
                if ($scope.PlaceCurrentPage > 0) {
                    $scope.places = angular.copy($rootScope.allPlaces.slice(($scope.PlaceCurrentPage - 1) * placePaging, $scope.PlaceCurrentPage * placePaging));
                    $scope.PlaceCurrentPage--;
                }
            };
            $scope.AddPlace = function (NewPlace, form) {
                if (form.$valid) {
                    $rootScope.AddplaceLoading = true;
                    PlaceServices.AddPlace(NewPlace);
                }
            };
            $scope.$on('placeAdded', function (event) {
                $scope.NewPlace = {
                    PlaceName: '',
                    Image: '',
                    PlaceCityId: '',
                    PlaceCordinates: '',
                    PlaceDesc: '',
                    PlaceAddress: ''
                };
                NewPlaceForm.imgUrl.value = "";
                $scope.NewPlaceForm.$setPristine();
                $scope.NewPlaceForm.$setUntouched();
                $scope.NewPlaceForm.$submitted = false;
                $scope.$broadcast('UpdatePlaces', {});
            });
            $scope.RemovePlace = function (PlaceID, PlaceName) {
                PlaceServices.RemovePlace(PlaceID, PlaceName);
            };
            $scope.$on('UpdatePlaces', function (event) {
                //console.log($scope.PlaceCurrentPage);
                PlaceServices.Get($scope.PlaceCurrentPage).
                    then(function (response) {
                        $rootScope.PlacePagesLen = response.data.PagesLen;
                        // $rootScope.PlaceCurrentPage = PageNum;
                        $rootScope.$broadcast('LoadFirstPlaceAudios', {});
                        $scope.places = response.data.Places;

                    }, function (response) {
                        console.log("Request failed");
                        console.log("status:" + response.status);
                    });
            });
            $scope.$on('UpdatePlaceValidationSummery', function (event, args) {
                $scope.additionalError = args.data;
                scroll("#NewPlace");
            });
            $scope.$on('PlaceForignKeyError', function (event, args) {
                $scope.ForignKeyErrorBody = 'This place (<span class="text-danger">' + args.PlaceName + '</span>) has some dependencies.<br />To remove this place, first you have to remove it\'s dependencies.'
                $scope.DelSubsBtn = "hidden";
                $('#ForignKeyErrorModal').modal('show');
            });
            $scope.$on('RemoveOnlinePlaceError', function (event, args) {
                $scope.ForignKeyErrorBody = 'This place (<span class="text-danger">' + args.PlaceName + '</span>) is online.<br />Removing online places is unallowable.'
                $scope.DelSubsBtn = "hidden";
                $('#ForignKeyErrorModal').modal('show');
            });
            $scope.$on('PlaceUnknownError', function (event) {
                $scope.ForignKeyErrorBody = 'Unknown error prevent removing place. Contact site developer to get more information.'
                $scope.DelSubsBtn = "hidden";
                $('#ForignKeyErrorModal').modal('show');
            });

            //Get Online
            $scope.GetOnlineVM = {};
            $scope.ShowGetOnlineModal = function (PlaceId, PlaceName) {
                $scope.GetOnlineVM.Id = PlaceId;
                $scope.GetOnlineVM.Name = PlaceName;
                $('#GoOnlineModal').modal('show');
            };
            $scope.GoOnline = function (PlaceId) {
                PlaceServices.GoOnline(PlaceId);
                $('#GoOnlineModal').modal('hide');
            };

            //Get Offline
            $scope.GetOfflineVM = {};
            $scope.ShowGetOfflineModal = function (PlaceId, PlaceName) {
                $scope.GetOfflineVM.Id = PlaceId;
                $scope.GetOfflineVM.Name = PlaceName;
                $('#GoOfflineModal').modal('show');
            };
            $scope.GoOffline = function (PlaceId) {
                PlaceServices.GoOffline(PlaceId);
            };

            //Edit Place
            $scope.EditPlaceVM;
            $scope.selectedPlace = {};
            $scope.ShowEditPlaceModal = function (Place) {

                getImages(Place.PlaceId, 0);
                getImages(Place.PlaceId, 1);

                $scope.selectedPlace.Img = Place.ImgUrl + "?" + new Date().getMilliseconds();
                $scope.selectedPlace.TumbImgUrl = Place.TumbImgUrl + "?" + new Date().getMilliseconds();
                $scope.selectedPlace.Id = Place.PlaceId;
                $scope.selectedPlace.PlaceTips = TipServices.getPlaceTips(Place.PlaceId);
                $scope.EditPlaceVM = angular.copy(Place);
                //{ id: '1', Content: 'vgjhbkn lm vybjnk' },
                //{ id: '2', Content: 'kl;dhjv; h/dm h;gb' }];
                $('#EditPlaceModal').modal('show');
            };
            $scope.EditPlace = function (EditPlaceVM) {
                //console.log(EditPlaceVM);
                $rootScope.EditOverlay = true;
                PlaceServices.Edit(EditPlaceVM);
            };
            $scope.ClickPlaceImg = function (id) {
                $(id).click();
            };
            $scope.ChangeImg = function (NewImage) {
                $rootScope.EditOverlay = true;
                PlaceServices.ChangeImage(NewImage.files[0], $scope.selectedPlace.Id)
            };
            $scope.ChangeTumbImg = function (NewImage) {
                $rootScope.EditOverlay = true;
                PlaceServices.ChangeTumbImg(NewImage.files[0], $scope.selectedPlace.Id)
            };
            $scope.AddExtraImage = function (image) {
                $scope.finishSaveImageExtra = false;
                PlaceServices.AddExtraImage(image.files[0], $scope.EditPlaceVM.PlaceId).
                    then(function (response) {
                        if (response.data.status == 0) {
                            getImages($scope.EditPlaceVM.PlaceId, 0);
                        }
                        else {
                            notific.error("ERROR", "Request failed");

                        }
                    }, function (response) {
                        console.log("Request failed");
                        notific.error("ERROR", "status:" + response.status);
                    });
            };
            $scope.AddGalleryImage = function (image) {
                $scope.finishSaveImageGallery = false;
                PlaceServices.AddGalleryImage(image.files[0], $scope.EditPlaceVM.PlaceId)
                    .then(function (response) {
                        if (response.data.status == 0) {
                            getImages($scope.EditPlaceVM.PlaceId, 1);
                        }
                        else {
                            notific.error("ERROR", "Request failed");
                            //console.log("Server failed to add Place.");
                        }
                    }, function (response) {
                        console.log("Request failed");
                        notific.error("ERROR", "status:" + response.status);
                    });;
            };
            $scope.RemoveExtraImg = function (img, type) {
                img.isLoading = true;
                PlaceServices.DelExtraImage(img.ImageId).
                    then(function (response) {
                        img.isLoading = false;
                        switch (response.data.status) {
                            case 0:
                                if (type == 0) {
                                    var index = $scope.selectedPlace.ExtraImages.indexOf(img);
                                    $scope.selectedPlace.ExtraImages.splice(index, 1);
                                }
                                else {
                                    var index = $scope.selectedPlace.GalleryImages.indexOf(img);
                                    $scope.selectedPlace.GalleryImages.splice(index, 1);

                                }
                                break;
                            case 2:
                                $rootScope.$broadcast('Invalid Id', {});

                                break;
                            case 3:
                                $rootScope.$broadcast('PlaceUnknownError', {});

                                break;
                            default:

                        }
                    }, function (response) {
                        console.log("Request failed");
                        notific.error("ERROR", "status:" + response.status);
                    });;
            };
            $scope.EditEIDescVM = {};
            $scope.EditEIDescModal = function (image) {
                $scope.EditEIDescVM = image;
                $('#EditEIDescModal').modal('show');
            };
            $scope.EditEIDesc = function (EditEIDescVM, form) {
                if (form.$valid) {
                    PlaceServices.EditEIDesc(EditEIDescVM).
                        then(function (response) {
                            $('#EditEIDescModal').modal('hide');
                        }, function (response) {
                            console.log("Request failed");
                            notific.error("ERROR", "status:" + response.status);
                        });;
                }
            };
            //$scope.$on('UpdateExtraImg', function (event) {
            //    PlaceServices.GetExtraImages(Place.PlaceId).
            //        then(function (response) {
            //            $scope.selectedPlace.ExtraImages = response.data
            //        }, function (response) {
            //            notific.error("ERROR", "Request failed");
            //        });
            //});

            $scope.$on('UpdateGalleryImg', function (event) {
                $scope.selectedPlace.GalleryImages = PlaceServices.GetGalleryImages(Place.PlaceId);

            });
            $scope.$on('EditPlaceValidationSummery', function (event, data) {
                console.log(data.data);
                //to be fill
            });
            $scope.$on('EditPlaceUnknownError', function (event) {
                //$scope.ForignKeyErrorBody = 'Unknown error prevent removing place. Contact site developer to get more information.'
                //$scope.DelSubsBtn = "hidden";
                //$('#ForignKeyErrorModal').modal('show');

            });
            $scope.$on('UpdatePlaceImage', function (event, data) {
                try {
                    var url = data.data + "?" + new Date().getMilliseconds();
                    $scope.selectedPlace.Img = url;
                    $rootScope.placeimage = url;


                }
                catch (error) {
                    console.log(error);
                }

            });
            $scope.$on('UpdatePlaceTumbImage', function (event, data) {
                try {
                    $scope.selectedPlace.TumbImgUrl = data.url + "?" + new Date().getMilliseconds();

                }
                catch (error) {
                    console.log(error);
                }
            });
            $scope.$on('UpdateImageValidationSummery', function (event, data) {
                console.log(data);
                //to be fill
            });
            //Tips
            $rootScope.allTipCategories = [];
            //{ id: '1', Class: 'ion-android-walk', name: '&#xf3bb; transportation', uniCode: '&#xf3bb;' },
            //{ id: '2', Class: 'ion-ios-pulse-strong', name: '&#xf492; rough trak', uniCode: '&#xf492;' }];
            TipServices.GetTipCategories();
            $scope.GetTipUniCode = function (id) {
                for (var i = 0; i < $scope.allTipCategories.length; i++) {
                    if ($scope.allTipCategories[i].id == id) {
                        return $scope.allTipCategories[i].unicode;
                    }
                }
                return '';
            }
            $scope.AddTip = function (model, placeId) {
                model.placeId = placeId;
                TipServices.AddTip(model);
            }
            $scope.$on('TipAdded', function (event, data) {
                $scope.newTip = {
                    categoryId: '',
                    content: ''
                };
                $scope.selectedPlace.PlaceTips = TipServices.getPlaceTips(data.PlaceId);
            });
            $scope.RemoveTip = function (TipId, placeId) {
                TipServices.RemoveTip(TipId, placeId);
            }
            $scope.$on('TipRemoved', function (event, data) {
                console.log(data);
                $scope.selectedPlace.PlaceTips = TipServices.getPlaceTips(data.PlaceId);
            });

            //City stuff
            $scope.CityNameValidator = "hidden";
            $rootScope.CityPagesLen;
            $rootScope.CityCurrentPage;
            $scope.AllCities = CityServices.All();
            $scope.cities = CityServices.Get(0);
            $scope.PreviousCity = function () {
                if ($rootScope.CityCurrentPage > 0)
                    $scope.cities = CityServices.Get($rootScope.CityCurrentPage - 1);
            };
            $scope.NextCity = function () {
                if ($rootScope.CityPagesLen - $rootScope.CityCurrentPage > 1)
                    $scope.cities = CityServices.Get($rootScope.CityCurrentPage + 1);
            };
            $scope.selectCityImg = false;
            $scope.AddCity = function (NewCity, form) {
                if (form.$valid && $scope.selectCityImg) {
                    $rootScope.AddCityLoading = true;
                    CityServices.AddCity(NewCity);

                }
            };
            $scope.EditCity = function (cityVM, form) {
                $rootScope.EditOverlay = true;
                if (form.$valid) {
                    CityServices.Edit(cityVM);
                }
            };
            $scope.ShowEditCityModal = function (City) {
                $scope.selectedCityImg = City.CityImageUrl + "?" + new Date().getMilliseconds();
                $scope.EditCityVM = angular.copy(City);
                $('#EditCityModal').modal('show');
            };
            $scope.ChangeCityImg = function (NewImage, id) {
                $rootScope.EditOverlay = true;
                CityServices.ChangeImage(NewImage.files[0], id)
            };

            $scope.$on('EditCityValidationSummery', function (event, data) {
                console.log(data.data);
                //to be fill
            });

            $scope.$on('EditCityUnknownError', function (event) {
                //$scope.ForignKeyErrorBody = 'Unknown error prevent removing place. Contact site developer to get more information.'
                //$scope.DelSubsBtn = "hidden";
                //$('#ForignKeyErrorModal').modal('show');

            });
            $scope.$on('cityAdded', function (event) {
                $scope.NewCity = {
                    CityName: '',
                    CityDesc: ''
                };
                $scope.NewCityForm.$setPristine();
                $scope.NewCityForm.$setUntouched();
                $scope.NewCityForm.$submitted = false;
                $scope.$broadcast('UpdateCities', {});
            });
            $scope.RemoveCity = function (CityID, CityName) {
                CityServices.RemoveCity(CityID, CityName);
            };
            $scope.$on('UpdateCities', function (event) {
                $scope.cities = CityServices.Get(0);
                $scope.AllCities = CityServices.All();
                scroll("#Cities");
            });
            $scope.$on('CityForignKeyError', function (event, args) {
                $scope.ForignKeyErrorBody = 'This city (<span class="text-danger">' + args.CityName + '</span>) has one or more places.<br />To remove this city, first you have to delete it\'s places.'
                $scope.DelSubsBtn = "hidden";
                $('#ForignKeyErrorModal').modal('show');
            });
            $scope.$on('CityUnknownError', function (event) {
                $scope.ForignKeyErrorBody = 'Unknown error prevent removing city. Contact site developer to get more information.'
                $scope.DelSubsBtn = "hidden";
                $('#ForignKeyErrorModal').modal('show');
            });



            // Amir section
            //Package stuff
            //$scope.PackageNameValidator = "hidden";
            $scope.PackagePagesLen;
            $scope.PackageCurrentPage;
            var AllPackages = [];
            $scope.packages = [];
            var setPckagesPagingInfo = function () {
                $scope.PackagePagesLen = Math.floor(AllPackages.length / paging);
                if ((AllPackages.length / paging > $scope.PackagePagesLen))
                    $scope.PackagePagesLen++;
            };

            $scope.NextPackage = function () {
                if ($scope.PackagePagesLen - $scope.PackageCurrentPage > 1) {
                    $scope.packages = angular.copy(AllPackages.slice(($scope.PlaceCPackageCurrentPageurrentPage + 1) * paging, ($scope.PlacePackageCurrentPageCurrentPage + 2) * paging));
                    $scope.PackageCurrentPage++;
                }
            };
            $scope.PreviousPackage = function () {
                if ($scope.PackageCurrentPage > 0) {
                    $scope.packages = angular.copy(AllPackages.slice(($scope.PackageCurrentPage - 1) * paging, $scope.PackageCurrentPage * paging));
                    $scope.PackageCurrentPage--;
                }
            };
            var getPackages = function () {
                PackageServices.All()
                    .then(function (response) {
                        AllPackages = response.data;
                        $scope.packages = AllPackages.slice(0, paging);
                        setPckagesPagingInfo();
                    }, function (response) {
                        console.error("Request failed:", response.status);
                    });
            };
            var resetAddPackageForm = function () {
                $scope.NewPackage = {
                    PackageName: '',
                    PackagePrice: ''
                };
                for (var i = 0; i < $scope.cities.length; i++)
                    $scope.cities[i].isSelected = false;
                $scope.PackageForm.$setPristine();
                $scope.PackageForm.$setUntouched();
                $scope.PackageForm.$submitted = false;
                getPackages();
                scroll("#Packages");
            };

            $scope.AddPackage = function (NewPackage, form) {

                if (form.$invalid) {
                    console.log("invalid form");
                }
                var cities = [];
                for (var i = 0; i < $scope.cities.length; i++) {
                    if ($scope.cities[i].isSelected) {
                        cities.push($scope.cities[i].CityID);
                    }
                }
                if (cities.length) {
                    $scope.selectCityInvalid = false;
                    NewPackage.Cities = cities;
                    $scope.AddPakageLoading = true;
                    PackageServices.AddPackage(NewPackage)
                        .then(function (response) {
                            $scope.AddPakageLoading = false;
                            switch (response.data.status) {
                                case respondstatus.success:
                                    resetAddPackageForm();
                                    break;
                                default:
                                    alert(response.status, "    message::::", response.content);
                                    break;
                            }
                        }, function (response) {
                            $scope.AddPakageLoading = false;
                            alert(response.status, "    message::::", response.content);
                            console.log("Request failed");
                            console.log("status:" + response.status);
                        });
                }
                else
                    $scope.selectCityInvalid = true;

            };
            $scope.selectCityInvalid = true;
            $scope.pkgcitiesTouched = false;
            $scope.checkSelectedCities = function () {
                $scope.pkgcitiesTouched = true;
                for (var i = 0; i < $scope.cities.length; i++)
                    if ($scope.cities[i].isSelected) {
                        $scope.selectCityInvalid = false;
                        return true;
                    }
                $scope.selectCityInvalid = true;
                return false;
            };
            $scope.choosInputClass = function (invalid, touched, submitted) {
                return (invalid && (touched || submitted)) ? "sorooshInvalid" : "";
            };
            $scope.selectAllCities = function (isSelected) {
                $scope.pkgcitiesTouched = true;
                $scope.selectCityInvalid = !isSelected;
                for (var i = 0; i < $scope.cities.length; i++)
                    $scope.cities[i].isSelected = isSelected;
            };

            getPackages();
        }]);

