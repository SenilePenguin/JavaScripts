function applyTableFilters() {
	var input, filter, table, tr, isShaded, td, i, z, txtValue;
	input = document.getElementById("inputFilter");
	filter = input.value.toUpperCase();
	table = document.getElementById("sort");
	tr = table.getElementsByTagName("tr");
	isShaded = new Boolean(false);
	
	for (i = 0; i < tr.length; i++) {
  
  	td = tr[i].getElementsByTagName("td")[0];
    	if (td) {        
        	var valid = 0;
            for (z = 0; z < tr[i].cells.length; z++) {            	
				txtValue = tr[i].getElementsByTagName("td")[z].textContent || tr[i].getElementsByTagName("td")[z].innerText;
    	    	
                if (txtValue.toUpperCase().indexOf(filter) > -1) {
    				valid = 1;
                }// if txtVal

            } // for z
            
            if (valid == 1) {
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
