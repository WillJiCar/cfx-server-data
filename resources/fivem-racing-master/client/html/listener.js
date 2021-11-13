$(function()
{
    window.addEventListener('message', function(event)
    {
        var item = event.data;
        if (item.meta)
        {
			if (item.meta == 'show')
			{
				$('#ptbl').html(item.text);
				$('#wrap').show();
				return;
			}
			if (item.meta == 'hide')
			{
				$('#tbl-data').html("");
				$('#wrap').hide();
				return;
			}
        }
    }, false);
});
