using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Models;

namespace WinApp.Controllers
{
    partial class HanhChinhController
    {
        protected override ViewDonVi CreateEntity() => new ViewDonVi { HanhChinhId = DonVi.CapHanhChinhDangXuLy };
        public object Add(ViewDonVi one) => View(new EditContext { Model = one, Action = EditActions.Insert });
        public override object Index()
        {
            return View(Select(null));
        }
        protected object Select(int? cap)
        {
            return DonVi.DanhSach(DonVi.CapHanhChinhDangXuLy = cap);
        }
        public object Huyen() => View(Select(2));
        public object Xa() => View(Select(3));

        protected override object Error(int code, string message)
        {
            if (UpdateContext.Action == EditActions.Delete)
            {
                message = $"{((ViewDonVi)UpdateContext.Model).TenDayDu} có các đơn vị con";
            }
            return base.Error(code, message);
        }

        protected override void TryDelete(ViewDonVi e)
        {
            // chặn xóa khi còn đơn vị con
            if (Provider.GetTable<DonVi>().GetValueById("TrucThuocId", e.Id) != null)
            {
                UpdateContext.Message = $"Cần xóa tất cả đơn vị con của {e.TenDayDu}";
                return;
            }

            // để DataController xử lý (PROC hoặc SQL)
            base.TryDelete(e);

            // cập nhật cache local
            DonVi.All.Remove(e);
        }

        protected override void TryInsert(ViewDonVi e)
        {
            base.TryInsert(e);
            DonVi.All.Clear(); // clear cache để load lại danh sách
        }

        protected override void TryUpdate(ViewDonVi e)
        {
            base.TryUpdate(e);
            DonVi.All.Clear();
        }

    }
}
