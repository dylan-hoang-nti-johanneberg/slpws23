let allButtons = document.querySelectorAll('.addToListbtn');

for (i = 0; i < allButtons.length; i++) {
    allButtons[i].addEventListener('click', function checkClick() {
        selectedProduct = this.parentElement;
        selectedProductName = selectedProduct.firstChild.innerHTML;
        let form = document.getElementById('CPUForm')
        form.value = selectedProductName
    })
}

// for (let button in allButtons) {
//     button.addEventListener('click', function checkClick() {
//         console.log(this);
//     })
// }

console.log("linked");