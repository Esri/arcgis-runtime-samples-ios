<h1>Search for webmap by keyword</h1>

<p>Shows how to search for webmaps within a portal using a keyword.</p>

![](image1.png)

<h2>How to use the sample</h2>

Input a keyword into the text field and press Enter to search. Click on a result to show the webmap in the map view. 

<h2>How it works</h2>

<p>To search for webmaps in a <code>AGSPortal</code> matching a keyword:</p>
<ol>
  <li>Create a <code>AGSPortal</code> and load it.</li>
  <li>Create <code>AGSPortalQueryParameters</code>. Set the type to <code>AGSPortalItemType.webMap</code> and the 
  query to the keyword you want to search.  Note that webmaps authored prior to July 2nd, 2014 are not supported - so search only from that date to the current time</li>
  <li>Use <code>portal.findItems(params)</code> to get the first set of matching items.</li>
</ol>
