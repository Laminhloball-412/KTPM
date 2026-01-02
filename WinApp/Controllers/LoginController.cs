using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WinApp.Controllers
{
    using Models;

    class LoginController : DataController<TaiKhoan>
    {
        public override object Index()
        {
            return View(new EditContext(new TaiKhoan { Ten = "dev", MatKhau = "1234" }));
        }
        protected override void UpdateCore(TaiKhoan acc)
        {
            var pass = acc.MatKhau;
            acc = DataEngine.Find<TaiKhoan>(acc.Ten);

            if (acc == null)
            {
                UpdateContext.Message = "Người dùng không tồn tại";
                return;
            }
            if (acc.MatKhau != pass)
            {
                UpdateContext.Message = "Sai mật khẩu";
                return;
            }

            // Lấy role từ cột Ext của bảng Quyen.
            // Ext nên là: Admin / Developer / Staff (tương ứng các class trong namespace Actors).
            var roleObj = Provider.GetTable<Quyen>().GetValueById("Ext", acc.QuyenId);
            var role = Convert.ToString(roleObj)?.Trim();

            // Nếu DB chưa có role hoặc role sai, fallback về Staff để tránh crash.
            if (string.IsNullOrWhiteSpace(role))
            {
                role = "Staff";
            }

            // Nếu role đã là full name (vd: Actors.Admin) thì dùng luôn.
            var fullTypeName = role.Contains(".") ? role : $"Actors.{role}";
            var asm = typeof(Actors.Admin).Assembly;
            var userType = asm.GetType(fullTypeName, throwOnError: false, ignoreCase: true);

            if (userType == null)
            {
                UpdateContext.Message = $"Role không hợp lệ: '{role}'. (Không tìm thấy class {fullTypeName})";
                return;
            }

            var u = (User)Activator.CreateInstance(userType);

            u.UserName = acc.Ten;
            if (acc.HoSoId != 0)
            {
                var p = Provider.GetTable<HoSo>().Find<HoSo>(acc.HoSoId);
                u.Description = p.Ten;
                u.Profile = p;
            }
            App.User = u;
        }

        static int errorCount = 0;
        protected override object UpdateError()
        {
            const int max = 3;
            if (errorCount == max)
            {
                App.Current.Shutdown();
                return null;
            }
            UpdateContext.Message += $".\nĐược phép sai thêm {max - (++errorCount)} lần.";
            return Error(1, UpdateContext.Message);
        }
        protected override object UpdateSuccess()
        {
            errorCount = 0;
            return Redirect("home");
        }
    }
}
