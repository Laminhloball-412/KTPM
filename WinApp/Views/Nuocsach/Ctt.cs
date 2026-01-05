using System.Windows;
using System.Windows.Controls;
using Vst.Controls;

namespace WinApp.Views.NuocSach
{
	class Ctt : BaseView<GridLayout>
	{
		public Ctt()
		{
			MainView.Children.Add(new TextBlock
			{
				Text = "CT Cấp nước tập trung (đang phát triển)",
				FontSize = 22,
				Margin = new Thickness(20)
			});
		}
		protected override void RenderCore(ViewContext ctx)
		{
			ctx.Title = "CT Cấp nước tập trung";
		}
	}
}
