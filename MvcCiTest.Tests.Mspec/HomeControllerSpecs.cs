using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.Mvc;
using Machine.Specifications;
using MvcCiTest.Controllers;

namespace MvcCiTest.Tests.Mspec {
    public class HomeControllerSpecs {

        [Subject(typeof(HomeController))]
        public class when_index_controller_is_requested {
            private static HomeController homeController;
            private Establish setup = () => {
                homeController = new HomeController();
            };
            private static ActionResult view;
            private Because of_index_is_requested = () => {
                view = homeController.Index();
            };
            private It message_is_set_to_view_bag = () => {
                ((string)homeController.ViewBag.Message).ShouldEqual("Welcome to ASP.NET MVC!");
            };
        }
    }
}
