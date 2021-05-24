function applyTableFilters() {
			var filter, table, tr, isShaded, td, i, z, txtValue, elems, cols;
			filter = document.getElementById("inputFilter").value.toUpperCase();
			table = document.getElementById("sort");
			tr = table.getElementsByTagName("tr");
			isValid = false; // Whether to show
			isShaded = false; // Alternates color on rows
			cols = []; // Initialize as an array. Will populate later.
			elems = table.getElementsByTagName("thead")[0].getElementsByTagName("th");

			var spl = filter.split("="); // Column search delimiter character

			// Fancy filter fixes to make it more intuitive.
			if (filter == "=" ||
				!filter.trim().length ||
				!spl[0].trim().length ||
				(spl[0] && filter.includes("=") && !spl[1])
			) { // Pretend the box is empty and query everything
				filter = "";
				spl[0] = spl[1] = undefined;
			}

			if (spl[1]) {
				// Go through all elements within the header
				for (var x = 0; x < elems.length; x++) {
					// If the column header is a match for the filter, add the index to an array
					if (fuzzyMatchString(elems[x].innerText, spl[0])) {
						cols.push(x);
						filter = spl[1];
					}
				}

			} // if spl[1]

			// If the filtering didn't find any results, add all columns to the array.
			if (cols.length <= 0) {
				for (var l = 0; l < elems.length; l++) {
					cols.push(l);
				} // for var l
			} // if cols.length

			for (i = 0; i < tr.length; i++) {
				td = tr[i].getElementsByTagName("td")[0];
				if (td) {
					isValid = false;
					for (z = 0; z < cols.length; z++) {
						isValid = fuzzyMatchElement(tr[i].getElementsByTagName("td")[cols[z]], filter);
						// If a single column is valid, show the row
						if (isValid) { z = tr[i].cells.length; } // Functions like a break statement
					} // for z

					if (isValid) {
						tr[i].style.display = "";
						if (isShaded) {
							tr[i].style.backgroundColor = "#ccc";
						} else {
							tr[i].style.backgroundColor = "";
						}
						isShaded = !isShaded;
					} else {
						tr[i].style.display = "none";
					} // if valid
				} // if td
			} // for i
		} // function

		function fuzzyMatchElement(inputElement, filter) {
			var txtValue = inputElement.innerText || inputElement.textContent;
			return fuzzyMatchString(txtValue, filter);
		}

		function fuzzyMatchString(inputString, filter) {
			return (inputString.toUpperCase().indexOf(filter) > -1);
		}
