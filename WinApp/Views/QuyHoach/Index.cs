using System.Windows;
using System.Windows.Controls;
using Vst.Controls;

namespace WinApp.Views.QuyHoach
{
    class Index : BaseView<GridLayout>
    {
        public Index()
        {
            MainView.Children.Add(new TextBlock
            {
                Text = "Quy hoạch Nước sạch (đang phát triển)",
                FontSize = 22,
                Margin = new Thickness(20)
            });
        }

        protected override void RenderCore(ViewContext context)
        {
            context.Title = "Quy hoạch Nước sạch";
        }
    }
}
