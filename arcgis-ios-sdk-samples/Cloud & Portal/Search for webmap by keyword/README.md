<h1>Search for webmap by keyword</h1>

<p>Shows how to search for webmaps within a portal using a keyword.</p>

<p><img src="WebmapKeywordSearch.png"/></p>

<h2>How to use the sample</h2>

Input a keyword into the text field and press Enter to search. Click on a result to show the webmap in the map view. 
Click on the "Find More Results" button to add more results to the list.

<h2>How it works</h2>

<p>To search for webmaps in a <code>Portal</code> matching a keyword:</p>
<ol>
  <li>Create a <code>Portal</code> and load it.</li>
  <li>Create <code>PortalItemQueryParameters</code>. Set the type to <code>PortalItem.Type.WEBMAP</code> and the 
  query to the keyword you want to search.</li>
  <li>Use <code>portal.findItemsAsync(params)</code> to get the first set of matching items.</li>
  <li>Get more results with <code>portal.findItemsAsync(portalQueryResultSet.getNextQueryParameters())</code>.</li>
</ol>
