using System.Windows;
using System.Windows.Controls;
using Vst.Controls;

namespace WinApp.Views.CongTrinh
{
    class TapTrung : BaseView<GridLayout>
    {
        public TapTrung()
        {
            MainView.Children.Add(new TextBlock
            {
                Text = "CT Cấp nước Tập trung (đang phát triển)",
                FontSize = 22,
                Margin = new Thickness(20)
            });
        }

        protected override void RenderCore(ViewContext context)
        {
            context.Title = "CT Cấp nước Tập trung";
        }
    }
}
