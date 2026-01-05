using System.Windows;
using System.Windows.Controls;
using Vst.Controls;

namespace WinApp.Views.Vbpl
{
    class Index : BaseView<GridLayout>
    {
        public Index()
        {
            MainView.Children.Add(new TextBlock
            {
                Text = "Hệ thống Văn bản (đang phát triển)",
                FontSize = 22,
                Margin = new Thickness(20)
            });
        }

        protected override void RenderCore(ViewContext context)
        {
            context.Title = "Hệ thống Văn bản";
        }
    }
}
