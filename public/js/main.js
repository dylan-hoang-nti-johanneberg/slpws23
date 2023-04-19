let allAddButtons = document.querySelectorAll('.addToListbtn');
let categoryButtons = document.querySelectorAll('.categoryBtn');
let productListView = document.getElementById("itemListView").childNodes;
let currentCategory = "CPU"

function createCategoryArray() {
    let categoryArray = document.getElementById("componentTypes").childNodes;
    console.log(categoryArray)

    for (i = 0; i < categoryArray.length; i++) {
        if (currentCategory == categoryArray[i].innerHTML) {
            productListView[i].classList.remove('hidden');
        }
    }   
}

for (i = 0; i < allAddButtons.length; i++) {
    allAddButtons[i].addEventListener('click', function productClick() {
        selectedProduct = this.parentElement;
        selectedProductName = selectedProduct.firstChild.innerHTML;
        selectedProductID = selectedProduct.lastChild.innerHTML;
        console.log(selectedProduct, selectedProductID, selectedProductName)
        let formText = document.getElementById(currentCategory);
        let formID = document.getElementById(`${currentCategory}_id`);
        console.log(formID, formText);
        formText.value = selectedProductName;
        formID.value = selectedProductID;
    })
}

for (i = 0; i < categoryButtons.length; i++) {
    categoryButtons[i].addEventListener('click', function categoryClick() {
        currentCategory = this.innerHTML;
        for (i = 0; i < productListView.length; i++) {
            if (!productListView[i].classList.contains('hidden')) {
                productListView[i].classList.add('hidden');
            }
        }
        currentCategory = this.innerHTML
        createCategoryArray()
    })
}

