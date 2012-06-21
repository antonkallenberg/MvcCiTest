$(function () {
    var bodyId = $('body').attr('id');
    if (bodyId === "HomePage") {
        var home = new HomePage();
        home.init();
    }else if (bodyId === "AboutPage") {
        var about = new AboutPage();
        about.init();
    }
});