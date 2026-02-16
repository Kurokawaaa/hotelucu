document.addEventListener("DOMContentLoaded", () => {
  const tierSelect = document.getElementById("tierSelect");
  if (!tierSelect) return;

  const facilityArea = document.getElementById("facilityArea");
  const facilityList = document.getElementById("facilityList");

  tierSelect.addEventListener("change", async () => {
    const id = tierSelect.value;
    if (!id) {
      facilityArea.style.display = "none";
      return;
    }

    const res = await fetch(`/admin/api/facilities/${id}`);
    const data = await res.json();

    facilityArea.style.display = "block";
    facilityList.innerHTML = "";

    data.forEach(f => {
      facilityList.innerHTML += `
        <li class="list-group-item d-flex justify-content-between">
          <span>${f.name}</span>
        </li>
      `;
    });
  });
});
