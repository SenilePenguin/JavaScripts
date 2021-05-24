// Add to your HTML Header: <script src="https://senilepenguin.github.io/PublicScripting/JavaScript/TabbedPaging/tabbedpaging.js"></script>

// USAGE:
// Create Buttons with: <button class="tablink" onclick="openPage('DIV_ID', this, 'color')" id="defaultOpen">VISIBLE_TEXT</button>
//      The 'defaultOpen' should only be specified once, and denotes which tab to select on page load.
// Each 'page' will be wrapped in a div with: <div id="DIV_ID" class="tabcontent">

function openPage(pageName, elmnt, color) {
	var i, tabcontent, tablinks;
	tabcontent = document.getElementsByClassName("tabcontent");
	for (i = 0; i < tabcontent.length; i++) {
		tabcontent[i].style.display = "none";
	}
	tablinks = document.getElementsByClassName("tablink");
	for (i = 0; i < tablinks.length; i++) {
		tablinks[i].style.backgroundColor = "";
	}
	document.getElementById(pageName).style.display = "block";
	if (!color) { elmnt.style.backgroundColor = "#ccc"; }
	else { elmnt.style.backgroundColor = color; }
}
// Get the element with id="defaultOpen" and click on it
document.getElementById("defaultOpen").click();
