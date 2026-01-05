using System.Windows;
using System.Windows.Controls;
using Vst.Controls;

namespace WinApp.Views.CoSo
{
	class Index : BaseView<GridLayout>
	{
		public Index()
		{
			MainView.Children.Add(new TextBlock
			{
				Text = "Cơ sở chăn nuôi & làng nghề (đang phát triển)",
				FontSize = 22,
				Margin = new Thickness(20)
			});
		}

		protected override void RenderCore(ViewContext context)
		{
			context.Title = "Cơ sở chăn nuôi & làng nghề";
		}
	}
}
