using System.Windows;
using System.Windows.Controls;
using Vst.Controls;

namespace WinApp.Views.CongTrinh
{
    class NhoLe : BaseView<GridLayout>
    {
        public NhoLe()
        {
            MainView.Children.Add(new TextBlock
            {
                Text = "CT Cấp nước Nhỏ lẻ (đang phát triển)",
                FontSize = 22,
                Margin = new Thickness(20)
            });
        }

        protected override void RenderCore(ViewContext context)
        {
            context.Title = "CT Cấp nước Nhỏ lẻ";
        }
    }
}
