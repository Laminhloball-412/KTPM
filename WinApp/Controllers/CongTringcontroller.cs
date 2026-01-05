namespace WinApp.Controllers
{
    class CongTrinhController : BaseController
    {
        public object TapTrung() => View("Views.CongTrinh.TapTrung", null);
        public object NhoLe() => View("Views.CongTrinh.NhoLe", null);
    }
}
